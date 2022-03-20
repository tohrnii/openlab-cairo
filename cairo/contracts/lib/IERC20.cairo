%lang starknet
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC20:
    func get_total_supply() -> (res: felt):
    end

    func get_decimals() -> (res: felt):
    end

    func balanceOf(account: felt) -> (res: Uint256):
    end

    func allowance(owner: felt, spender: felt) -> (res: felt):
    end

    func transfer(recipient: felt, amount: Uint256):
    end

    func transferFrom(sender: felt, recipient: felt, amount: Uint256):
    end

    func approve(spender: felt, amount: felt):
    end
end