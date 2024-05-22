#[starknet::interface]
trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);    
}


#[starknet::contract]
mod Counter {
use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
use core::starknet::event::EventEmitter;
use starknet::ContractAddress;
use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};
use openzeppelin::access::ownable::OwnableComponent;

component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

#[abi(embed_v0)]
impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;


    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        #[key]
        counter: u32,
    }


    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u32, kill_switch_address: ContractAddress, initial_owner: ContractAddress) {
        self.counter.write(initial_value);
        self.kill_switch.write(kill_switch_address);
        self.ownable.initializer(initial_owner);
    }


    #[abi(embed_v0)]
    impl ICounterImpl of super::ICounter<ContractState>{
        fn get_counter(self: @ContractState) -> u32{
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState){
            self.ownable.assert_only_owner();
            let contract_address = self.kill_switch.read();
            if (IKillSwitchDispatcher{contract_address}.is_active() == false){  
                self.counter.write(self.counter.read() + 1);
                self.emit(CounterIncreased{counter: self.counter.read()});
            }else{
                panic!("Kill Switch is active");
            }
          
        }

    }

}