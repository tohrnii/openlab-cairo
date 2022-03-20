import os
import pytest
from starkware.starknet.testing.starknet import Starknet
from Bio.Seq import Seq
from utils import str_to_felt, felt_to_str, Signer, uint256
import time

async def calculate_revcomp(input_file, output_file):
    with open(os.path.join("processed", input_file), 'r') as file:
        input_string = file.read().rstrip()
    my_revcomp = Seq(input_string).reverse_complement()
    with open(os.path.join("processed", output_file), "w") as text_file:
        text_file.write(str(my_revcomp))
    print("Input String: ", input_string)
    print("Revcomp: ", my_revcomp)

# The path to the contract source code.
REGISTRY_CONTRACT_FILE = os.path.join("contracts", "Registry.cairo")
ACCOUNT_FILE = os.path.join("contracts", "lib", "Account.cairo")
ERC20_FILE = os.path.join("contracts", "mock", "ERC20.cairo")

user = Signer(69)
service_provider = Signer(420)

@pytest.mark.asyncio
async def test_openlab():
    
    starknet = await Starknet.empty()
    user_account = await starknet.deploy(
        ACCOUNT_FILE,
        constructor_calldata=[user.public_key]
    )
    service_provider_account = await starknet.deploy(
        ACCOUNT_FILE,
        constructor_calldata=[service_provider.public_key]
    )
    registry_contract = await starknet.deploy(source=REGISTRY_CONTRACT_FILE)
    lab_erc20 = await starknet.deploy(
        source=ERC20_FILE,
        constructor_calldata=[
            str_to_felt('Lab'),
            str_to_felt('LAB'),
            18,
            *uint256(100000),
            user_account.contract_address
        ]
    )

    #approve
    await user.send_transaction(user_account, lab_erc20.contract_address, 'approve', [registry_contract.contract_address, *uint256(100000)])
    
    #add job1
    await user.send_transaction(
        user_account,
        registry_contract.contract_address,
        'add_job',
        [
            lab_erc20.contract_address,
            *uint256(100),
            0,
            str_to_felt("revcomp"),
            int(time.time())+60*24,
            str_to_felt("input.txt"),
            str_to_felt("out1.txt")
        ]
    )

    # get LAB balance
    erc20_balance = (await lab_erc20.balanceOf(user_account.contract_address).call()).result.balance
    print("User LAB Balance after job 1 added: ", erc20_balance)

    #add job2
    await user.send_transaction(
        user_account,
        registry_contract.contract_address,
        'add_job',
        [
            lab_erc20.contract_address,
            *uint256(100),
            0,
            str_to_felt("revcomp"),
            int(time.time())+60*24,
            str_to_felt("out1.txt"),
            str_to_felt("out2.txt")
        ]
    )

    # get LAB balance
    erc20_balance = (await lab_erc20.balanceOf(user_account.contract_address).call()).result.balance
    print("User LAB Balance after job 2 added: ", erc20_balance)

    #add job3
    await user.send_transaction(
        user_account,
        registry_contract.contract_address,
        'add_job',
        [
            lab_erc20.contract_address,
            *uint256(100),
            0,
            str_to_felt("revcomp"),
            int(time.time())+60*24,
            str_to_felt("out2.txt"),
            str_to_felt("out3.txt")
        ]
    )

    # get LAB balance
    erc20_balance = (await lab_erc20.balanceOf(user_account.contract_address).call()).result.balance
    print("User LAB Balance after job 3 added: ", erc20_balance)

    #accept job1
    await service_provider.send_transaction(
        service_provider_account,
        registry_contract.contract_address,
        'accept_job',
        [
            1
        ]
    )
    job1 = (await registry_contract.get_job(1).call()).result.res
    print(job1)
    await calculate_revcomp(felt_to_str(job1.input_file).replace('\x00', ''), felt_to_str(job1.output_file).replace('\x00', ''))

    #complete job1
    await service_provider.send_transaction(
        service_provider_account,
        registry_contract.contract_address,
        'complete_job',
        [
            1
        ]
    )

    # get LAB balance
    erc20_balance = (await lab_erc20.balanceOf(service_provider_account.contract_address).call()).result.balance
    print("Service provider LAB Balance after job 1 completed: ", erc20_balance)

    #accept job2
    await service_provider.send_transaction(
        service_provider_account,
        registry_contract.contract_address,
        'accept_job',
        [
            2
        ]
    )
    job2 = (await registry_contract.get_job(2).call()).result.res
    print(job2)
    await calculate_revcomp(felt_to_str(job2.input_file).replace('\x00', ''), felt_to_str(job2.output_file).replace('\x00', ''))

    #complete job2
    await service_provider.send_transaction(
        service_provider_account,
        registry_contract.contract_address,
        'complete_job',
        [
            2
        ]
    )

    # get LAB balance
    erc20_balance = (await lab_erc20.balanceOf(service_provider_account.contract_address).call()).result.balance
    print("Service provider LAB Balance after job 2 completed: ", erc20_balance)

    #accept job3
    await service_provider.send_transaction(
        service_provider_account,
        registry_contract.contract_address,
        'accept_job',
        [
            3
        ]
    )
    job3 = (await registry_contract.get_job(3).call()).result.res
    print(job3)
    await calculate_revcomp(felt_to_str(job3.input_file).replace('\x00', ''), felt_to_str(job3.output_file).replace('\x00', ''))

    #complete job3
    await service_provider.send_transaction(
        service_provider_account,
        registry_contract.contract_address,
        'complete_job',
        [
            3
        ]
    )

    # get LAB balance
    erc20_balance = (await lab_erc20.balanceOf(service_provider_account.contract_address).call()).result.balance
    print("Service provider LAB Balance after job 3 completed: ", erc20_balance)