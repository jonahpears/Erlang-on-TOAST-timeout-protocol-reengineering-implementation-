-module('basic_send_recv_loop__ali_test.erl').

-file("basic_send_recv_loop__ali_test.erl", 1).

-define(MONITORED, false).

-define(MONITOR_SPEC,
        #{init => init_state, map => #{state1_std => #{send => #{msgA => {state2_std, []}}}, state2_std => #{recv => #{msg1 => {state2_std, []}}}},
          timeouts => #{}, resets => #{unresolved => #{}}, timers => #{}}).

-define(PROTOCOL_SPEC, {act, s_msgA, {rec, "a", {act, r_msg1, {rvar, "a"}}}}).

-include("stub.hrl").

-export([]).

run(CoParty) -> run(CoParty, #{timers => #{}, msgs => #{}}).

run(CoParty, Data) -> main(CoParty, Data).

main(CoParty, Data) ->
    CoParty ! {self(), msgA, Payload},
    loop_standard_state(CoParty, Data).

loop_standard_state(CoParty, Data2) ->
    receive
        {CoParty, msg1, Payload_Msg1} ->
            Data2 = save_msg(msg1, Payload_Msg1, Data2),
            loop_standard_state(CoParty, Data2)
    end.