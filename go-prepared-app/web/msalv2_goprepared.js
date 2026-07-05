// Patched copy of aad_oauth msalv2.js — adds completeRedirect for OAuth callback completion.
// Upstream refreshToken() never calls onError when MSAL has no cached account (hangs forever).
var aadOauth = (function () {
  let myMSALObj = null;
  let authResult = null;
  let redirectHandlerTask = null;

  const tokenRequest = {
    scopes: null,
    prompt: null,
    extraQueryParameters: {},
    loginHint: null
  };

  function init(config) {
    // Early bootstrap in index.html may have already initialized MSAL for redirect handling.
    if (myMSALObj !== null) {
      return;
    }
    var authData = {
      clientId: config.clientId,
      authority: config.isB2C ? "https://" + config.tenant + ".b2clogin.com/tfp/" + config.tenant + ".onmicrosoft.com/" + config.policy + "/" : "https://login.microsoftonline.com/" + config.tenant,
      knownAuthorities: [config.tenant + ".b2clogin.com", "login.microsoftonline.com"],
      redirectUri: config.redirectUri,
    };
    var postLogoutRedirectUri = {
      postLogoutRedirectUri: config.postLogoutRedirectUri,
    };
    var msalConfig = {
      auth: config?.postLogoutRedirectUri == null ? {
        ...authData,
      } : {
        ...authData,
        ...postLogoutRedirectUri,
      },
      cache: {
        cacheLocation: config.cacheLocation,
        storeAuthStateInCookie: true,
      },
    };

    if (typeof config.scope === "string") {
      tokenRequest.scopes = config.scope.split(" ");
    } else {
      tokenRequest.scopes = config.scope;
    }

    tokenRequest.extraQueryParameters = JSON.parse(config.customParameters);
    tokenRequest.prompt = config.prompt;
    tokenRequest.loginHint = config.loginHint;

    myMSALObj = new msal.PublicClientApplication(msalConfig);
    redirectHandlerTask = myMSALObj.handleRedirectPromise().catch(function (error) {
      var message = (error && (error.message || error.errorMessage)) || String(error);
      try {
        localStorage.setItem('gp_msal_error', message);
        sessionStorage.setItem('gp_msal_error', message);
      } catch (e) {}
      return null;
    });
  }

  async function silentlyAcquireToken() {
    const account = getAccount();
    if (account == null) {
      return null;
    }

    try {
      const silentAuthResult = await myMSALObj.acquireTokenSilent({
        scopes: tokenRequest.scopes,
        prompt: "none",
        account: account,
        extraQueryParameters: tokenRequest.extraQueryParameters
      });

      return authResult = silentAuthResult;
    } catch (error) {
      console.log('Unable to silently acquire a new token: ' + error.message);
      return null;
    }
  }

  async function awaitRedirectResult(onError) {
    try {
      const result = await redirectHandlerTask;
      if (result !== null) {
        authResult = result;
      }
      return true;
    } catch (error) {
      onError(error);
      return false;
    }
  }

  async function login(refreshIfAvailable, useRedirect, onSuccess, onError) {
    const ok = await awaitRedirectResult(onError);
    if (!ok) return;

    await silentlyAcquireToken();

    if (authResult != null) {
      onSuccess(authResult.accessToken ?? null);
      return;
    }

    const account = getAccount();

    if (useRedirect) {
      myMSALObj.acquireTokenRedirect({
        scopes: tokenRequest.scopes,
        prompt: tokenRequest.prompt,
        account: account,
        extraQueryParameters: tokenRequest.extraQueryParameters,
        loginHint: tokenRequest.loginHint
      });
    } else {
      try {
        const interactiveAuthResult = await myMSALObj.loginPopup({
          scopes: tokenRequest.scopes,
          prompt: tokenRequest.prompt,
          account: account,
          extraQueryParameters: tokenRequest.extraQueryParameters,
          loginHint: tokenRequest.loginHint
        });

        authResult = interactiveAuthResult;
        onSuccess(authResult.accessToken ?? null);
      } catch (error) {
        console.warn(error.message);
        onError(error);
      }
    }
  }

  async function refreshToken(onSuccess, onError) {
    const ok = await awaitRedirectResult(onError);
    if (!ok) return;

    await silentlyAcquireToken();

    if (authResult != null) {
      onSuccess(authResult.accessToken ?? null);
      return;
    }

    onError('No Microsoft session found after redirect.');
  }

  /// Completes MSAL redirect flow only — never starts a new redirect or popup.
  async function completeRedirect(onSuccess, onError) {
    const ok = await awaitRedirectResult(onError);
    if (!ok) return;

    await silentlyAcquireToken();

    if (authResult != null) {
      onSuccess(authResult.accessToken ?? null);
      return;
    }

    onError(
      'Microsoft sign-in could not be completed. Clear site data for this URL and try again, ' +
      'or confirm the redirect URI in Azure matches this page exactly.'
    );
  }

  function getAccount() {
    if (authResult !== null && authResult.account !== null) {
      return authResult.account;
    }

    const currentAccounts = myMSALObj.getAllAccounts();

    if (currentAccounts === null || currentAccounts.length === 0) {
      return null;
    } else if (currentAccounts.length > 1) {
      console.warn("Multiple accounts detected, selecting first.");
      return currentAccounts[0];
    } else if (currentAccounts.length === 1) {
      return currentAccounts[0];
    }
  }

  function logout(onSuccess, onError, showPopup) {
    const account = getAccount();

    if (!account) {
      onSuccess();
      return;
    }

    authResult = null;
    tokenRequest.scopes = null;

    if (showPopup) {
      myMSALObj
        .logout({ account: account })
        .then((_) => onSuccess())
        .catch(onError);
    } else {
      myMSALObj
        .logoutRedirect({
          account: account,
          onRedirectNavigate: (url) => {
            return false;
          }
        })
        .then((_) => onSuccess())
        .catch(onError);
    }
  }

  async function getAccessToken() {
    var result = await silentlyAcquireToken();
    return result ? result.accessToken : null;
  }

  async function getIdToken() {
    var result = await silentlyAcquireToken();
    return result ? result.idToken : null;
  }

  function hasCachedAccountInformation() {
    return getAccount() != null;
  }

  return {
    init: init,
    login: login,
    refreshToken: refreshToken,
    completeRedirect: completeRedirect,
    logout: logout,
    getIdToken: getIdToken,
    getAccessToken: getAccessToken,
    hasCachedAccountInformation: hasCachedAccountInformation,
  };
})();
