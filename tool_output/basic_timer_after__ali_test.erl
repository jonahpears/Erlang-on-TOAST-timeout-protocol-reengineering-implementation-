-module('basic_timer_after__ali_test.erl').

-file("basic_timer_after__ali_test.erl", 1).

-define(MONITORED, false).

-define(MONITOR_SPEC,
        #{init => init_state, map => #{state1_std => #{send => #{before_t => {state2_unexpected_timer_start_state, []}}}}, timeouts => #{},
          resets => #{unresolved => #{}, state1_std => #{t => 5000}}, timers => #{}}).

-define(PROTOCOL_SPEC, {act, s_before_t, {timer, "t", 5000, endP}}).

-include("stub.hrl").

-export([]).

run(CoParty) -> run(CoParty, #{timers => #{}, msgs => #{}}).

run(CoParty, Data) -> main(CoParty, Data).

main(CoParty, Data) ->
    CoParty ! {self(), before_t, Payload},
    {Data, _TID_t} = set_timer(t, 5000, Data),
    stopping(CoParty, Data).

stopping(CoParty, Data) -> stopping(normal, CoParty, Data).

stopping(normal = _Reason, _CoParty, _Data) -> exit(normal);
stopping({error, Reason, Details}, _CoParty, _Data) when is_atom(Reason) -> erlang:error(Reason, Details);
stopping({error, Reason}, CoParty, Data) when is_atom(Reason) -> stopping({error, Reason, []}, CoParty, Data);
stopping(Reason, _CoParty, _Data) when is_atom(Reason) -> exit(Reason).