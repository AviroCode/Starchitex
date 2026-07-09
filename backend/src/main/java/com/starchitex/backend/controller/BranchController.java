package com.starchitex.backend.controller;

import com.starchitex.backend.model.Branch;
import com.starchitex.backend.service.BranchService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/branches")
public class BranchController {

    private final BranchService branchService;

    public BranchController(BranchService branchService) {
        this.branchService = branchService;
    }

    @GetMapping
    public List<Branch> getAllBranches() {
        return branchService.getAllBranches();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Branch> getBranchById(@PathVariable int id) {
        return branchService.getBranchById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<String> createBranch(@RequestBody Branch branch) {
        boolean isCreated = branchService.createBranch(branch);
        if (isCreated) {
            return ResponseEntity.status(201).body("Branch Created Successfully");

        } else {
            return ResponseEntity.status(400).body("Failed to create branch");
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<String> updateBranch(@PathVariable int id, @RequestBody Branch branch) {
        Branch branchToUpdate = new Branch(
            id,
            branch.name(),
            branch.address(),
            branch.city(),
            branch.province(),
            branch.postalCode(),
            branch.email(),
            branch.phone(),
            branch.status()
        );

        boolean isUpdated = branchService.updateBranch(branchToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Branch updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update branch. Check if ID exists.");
        }
    }
}
