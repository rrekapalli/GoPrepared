package com.goprepared.api.ai.workflows;

import com.goprepared.api.ai.dto.AiContracts.ChecklistItem;
import com.goprepared.api.ai.dto.AiContracts.JourneyClassification;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;

@Service
public class ChecklistGenerationWorkflow {

    public List<ChecklistItem> generate(JourneyClassification classification) {
        String q = classification.title().toLowerCase(Locale.ROOT);
        if (q.contains("bali") || q.contains("vacation")) {
            return baliChecklist();
        }
        if (q.contains("10k") || q.contains("vizag") || q.contains("run")) {
            return raceChecklist();
        }
        if (q.contains("angiogram")) {
            return medicalChecklist();
        }
        return genericChecklist(classification.title());
    }

    private List<ChecklistItem> baliChecklist() {
        List<ChecklistItem> items = new ArrayList<>();
        items.add(item("Lightweight cotton shirts", "Breathable tops for humidity", "Clothing", 0));
        items.add(item("Swimwear", "For beach days", "Clothing", 1));
        items.add(item("Sarong for temples", "Required at many sacred sites", "Clothing", 2));
        items.add(item("Sunscreen (SPF 50+)", "Strong tropical sun protection", "Health & Safety", 3));
        items.add(item("Insect repellent", "Dengue prevention in wet season", "Health & Safety", 4));
        items.add(item("Personal first aid kit", "Basics for minor injuries", "Health & Safety", 5));
        items.add(item("Digital copy of passport", "Store in secure cloud folder", "Documents", 6));
        items.add(item("Booking confirmations", "Hotels, flights, activities", "Documents", 7));
        return items;
    }

    private List<ChecklistItem> raceChecklist() {
        return List.of(
                item("Running bib and timing chip", "Pick up at expo", "Race Day", 0),
                item("Hydration plan", "Electrolytes for humid coastal run", "Nutrition", 1),
                item("Post-race recovery kit", "Change of clothes and sandals", "Recovery", 2));
    }

    private List<ChecklistItem> medicalChecklist() {
        return List.of(
                item("Fast from midnight", "Per hospital instructions", "Pre-Procedure", 0),
                item("List of current medications", "Share with care team", "Documents", 1),
                item("Comfortable recovery clothing", "Loose fit for procedure site", "Recovery", 2));
    }

    private List<ChecklistItem> genericChecklist(String title) {
        return List.of(
                item("Review official guidance", "Check authoritative sources", "General", 0),
                item("Gather required documents", "For " + title, "Documents", 1),
                item("Set reminders", "Key dates and deadlines", "Planning", 2));
    }

    private ChecklistItem item(String title, String description, String category, int order) {
        return new ChecklistItem(title, description, category, order, false);
    }
}
