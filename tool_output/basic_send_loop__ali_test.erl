-module('basic_send_loop__ali_test.erl').

-file("basic_send_loop__ali_test.erl", 1).

-define(MONITORED, false).

-define(MONITOR_SPEC, #{}).

-include("stub.hrl").

-export([]).

%% @doc Adds default empty list for Data.
%% @see run/2.
run(CoParty) -> run(CoParty, []).

%% @doc Called immediately after a successful initialisation.
%% Add any setup functionality here, such as for the contents of Data.
%% @param CoParty is the process ID of the other party in this binary session.
%% @param Data is a list to store data inside to be used throughout the program.
run(CoParty, Data) -> main(CoParty, Data). %% add any init/start preperations below, before entering main

main(CoParty, Data) ->
    Data1 = Data,
    Payload_MsgA = payload,
    CoParty ! {self(), msgA, Payload_MsgA},
    loop_state1_std(CoParty, Data1).

loop_state1_std(CoParty, Data1) ->
    Data1_1 = Data1,
    Payload_MsgA = payload,
    CoParty ! {self(), msgA, Payload_MsgA},
    loop_state1_std(CoParty, Data1_1).