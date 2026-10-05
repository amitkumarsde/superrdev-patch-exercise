package com.internal.tasktracker;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@CrossOrigin(origins = "http://localhost:5173")
public class TaskController {

    private static final Logger log = LoggerFactory.getLogger(TaskController.class);

    // Upper limit so one request cannot ask for a huge page.
    private static final int MAX_PAGE_SIZE = 100;

    private final TaskRepository taskRepository;

    public TaskController(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    @GetMapping("/api/tasks")
    public ResponseEntity<?> searchTasks(
            @RequestParam(required = false, defaultValue = "") String q,
            @RequestParam(required = false) String status,
            @RequestParam(required = false, defaultValue = "1") int page,
            @RequestParam(required = false, defaultValue = "10") int pageSize) {

        // Bad paging values used to crash subList() with a 500; reply with a clear 400 instead.
        if (page < 1 || pageSize < 1 || pageSize > MAX_PAGE_SIZE) {
            return badRequest("page must be >= 1 and pageSize must be between 1 and " + MAX_PAGE_SIZE);
        }

        // Normalize query input
        String query = q == null ? "" : q.trim();
        String searchTerm = "%" + escapeLike(query.toLowerCase()) + "%";

        // Parse status filter. An unknown value used to throw and return a 500.
        String normalizedStatus = null;
        if (status != null && !status.isBlank()) {
            try {
                normalizedStatus = TaskStatus.valueOf(status.trim().toUpperCase()).name();
            } catch (IllegalArgumentException e) {
                return badRequest("Unknown status '" + status + "'. Allowed: " + Arrays.toString(TaskStatus.values()));
            }
        }

        // Removed a fake "complexity" Thread.sleep that delayed short searches by up to 1 second.

        log.debug("Searching tasks: qLength={} status={} page={} pageSize={}",
                query.length(), normalizedStatus, page, pageSize);

        // Note: all matches are loaded and paged in memory. Fine for this data size;
        // move paging into SQL (LIMIT/OFFSET) if the table grows large.
        List<Task> allResults = taskRepository.searchTasks(searchTerm, normalizedStatus);

        // Use long so a very big page number cannot overflow into a negative index.
        long start = (long) (page - 1) * pageSize;
        List<Task> pageResults = (start < allResults.size())
                ? allResults.subList((int) start, (int) Math.min(start + pageSize, allResults.size()))
                : Collections.emptyList();

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("items", pageResults);
        response.put("total", allResults.size());
        response.put("page", page);
        response.put("pageSize", pageSize);

        return ResponseEntity.ok(response);
    }

    // Treat % and _ typed by the user as normal letters, not SQL wildcards.
    // H2 uses backslash as its default LIKE escape character.
    private static String escapeLike(String value) {
        return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }

    private static ResponseEntity<Map<String, String>> badRequest(String message) {
        return ResponseEntity.badRequest().body(Map.of("error", message));
    }
}
