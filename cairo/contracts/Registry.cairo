# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_not_zero, assert_le, assert_lt)
from starkware.cairo.common.uint256 import (Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check)
from starkware.starknet.common.syscalls import (get_block_number, get_block_timestamp, get_caller_address, get_contract_address)
from starkware.cairo.common.math_cmp import is_le
from contracts.lib.IERC20 import IERC20

#job status:
#1 => pending but not active
#2 => active
#3 => accepted
#4 => submitted
#5 => failed

struct Job:
    member user: felt
    member payment_token: felt
    member payment_value: Uint256
    member status: felt
    member parent_job_id: felt
    member child_job_id: felt
    member process: felt
    member deadline: felt
    member service_provider: felt
    member input_file: felt
    member output_file: felt
end

@event
func JobAdded(job_id: felt):
end

@storage_var
func jobs(job_id: felt) -> (job_description: Job):
end

@storage_var
func get_total_jobs() -> (res: felt):
end

@external
func add_job{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        payment_token: felt,
        payment_value: Uint256,
        parent_job_id: felt,
        process: felt,
        deadline: felt,
        input_file: felt,
        output_file: felt
    ):
    alloc_locals
    let (local caller: felt) = get_caller_address()
    let (local this_contract: felt) = get_contract_address()
    let (local total_jobs: felt) = get_total_jobs.read()
    let _status = 1
    # let (local block_timestamp: felt) = get_block_timestamp()
    # assert_lt(block_timestamp, deadline)
    IERC20.transferFrom(contract_address=payment_token, sender=caller, recipient=this_contract, amount=payment_value) #transfer token to this contract (escrow)
    if parent_job_id != 0:
        assert_lt(parent_job_id, total_jobs)
        let (local parent_job: Job) = jobs.read(parent_job_id)
        assert parent_job.status = 4

        jobs.write(
            parent_job_id, 
            Job(
                user = parent_job.user,
                payment_token = parent_job.payment_token,
                payment_value = parent_job.payment_value,
                status = parent_job.status,
                parent_job_id = parent_job.parent_job_id,
                child_job_id = total_jobs+1,
                process = parent_job.process,
                deadline = parent_job.deadline,
                service_provider = parent_job.service_provider,
                input_file = parent_job.input_file,
                output_file = parent_job.output_file
            )
        )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar _status = _status
    else:
        let _status = 2
        assert parent_job_id = 0
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar _status = _status
    end
    jobs.write(
        total_jobs+1,
        Job(
            user = caller,
            payment_token = payment_token, 
            payment_value = payment_value,
            status = _status,
            parent_job_id = parent_job_id,
            child_job_id = 0,
            process = process,
            deadline = deadline,
            service_provider = 0,
            input_file = input_file,
            output_file = output_file
        )
    )
    get_total_jobs.write(total_jobs+1)
    JobAdded.emit(total_jobs+1)

    return ()
end

@external
func accept_job{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        job_id: felt
    ):
    let (job) = jobs.read(job_id)
    assert job.status = 2
    assert job.service_provider = 0
    # let (block_timestamp) = get_block_timestamp()
    # assert_lt(block_timestamp, job.deadline)
    set_job_status(job_id, 3)
    return ()
end

@external
func complete_job{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        job_id: felt
    ):
    alloc_locals
    let (local job) = jobs.read(job_id)
    assert job.status = 3
    let (caller) = get_caller_address()
    # assert caller = job.service_provider #TODO
    # let (block_timestamp) = get_block_timestamp()
    # assert_lt(block_timestamp, job.deadline)
    set_job_status(job_id, 4)
    if job.child_job_id != 0:
        set_job_status(job.child_job_id, 2)
    end
    IERC20.transfer(contract_address=job.payment_token, recipient=caller, amount=job.payment_value) #transfer token to service provider
    return ()
end


@external
func mark_job_as_failed{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        job_id: felt
    ):
    alloc_locals
    let (local job: Job) = jobs.read(job_id)
    assert_le(job.status, 3)
    # let (block_timestamp) = get_block_timestamp()
    # assert_lt(job.deadline, job.deadline)
    set_job_status(job_id, 5)
    let (this_contract) = get_contract_address()
    IERC20.transfer(contract_address=job.payment_token, recipient=job.user, amount=job.payment_value) #transfer token to user
    return ()
end

@view
func check_status{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        job_id: felt
    ) -> (res: felt):
    let (job) = jobs.read(job_id)
    return (job.status)
end

@view
func get_job{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        job_id: felt
    ) -> (res: Job):
    let (job) = jobs.read(job_id)
    return (job)
end

func set_job_status{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        job_id: felt,
        status: felt
    ):
    let (job) = jobs.read(job_id)
    jobs.write(
        job_id, 
        Job(
            user = job.user,
            payment_token = job.payment_token,
            payment_value = job.payment_value,
            status = status,
            parent_job_id = job.parent_job_id,
            child_job_id = job.child_job_id,
            process = job.process,
            deadline = job.deadline,
            service_provider = job.service_provider,
            input_file = job.input_file,
            output_file = job.output_file,
        )
    )
    return ()
end