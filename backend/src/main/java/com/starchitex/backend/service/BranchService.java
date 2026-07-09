package com.starchitex.backend.service;

import com.starchitex.backend.model.Branch;
import com.starchitex.backend.repository.BranchRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class BranchService {

    private final BranchRepository branchRepository;

    public BranchService(BranchRepository branchRepository) {
        this.branchRepository = branchRepository;
    }

    public List<Branch> getAllBranches() {
        return branchRepository.findAll();
    }

    public Optional<Branch> getBranchById(int id) {
        return branchRepository.findById(id);
    }

    public boolean createBranch(Branch branch) {
        return branchRepository.save(branch) > 0;
    }

    public boolean updateBranch(Branch branch) {
        return branchRepository.update(branch) > 0;
    }

}
