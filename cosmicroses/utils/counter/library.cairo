// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub


namespace Counter {

    //  * ======================= *
    //  * ====== EXTERNALS ====== *
    //  * ======================= *

    func increment{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(counter: Uint256) -> (incremented_counter: Uint256){

        let incremented_counter = uint256_add(counter, Uint256(1,0)); 
        return (incremented_counter.res,);
    }

    func decrement{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(counter: Uint256) -> (decremented_counter: Uint256){

        let decremented_counter = uint256_sub(counter, Uint256(1,0)); 
        return (decremented_counter.res,);
    }
}


