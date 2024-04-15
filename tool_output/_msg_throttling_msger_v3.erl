-module('_msg_throttling_msger_v3').

-behaviour(gen_statem).

-define(SERVER, ?MODULE).

-export([callback_mode/0,
         custom_end_state/3,
         init/1,
         receive_ack1/1,
         receive_ack2/1,
         send_msg1/1,
         send_msg2/1,
         send_tout/1,
         start_link/0,
         state1_std/3,
         state2_recv_after/3,
         state3_std/3,
         state4_recv_after/3,
         state5_std/3,
         stop/0,
         terminate/3]).

-file("_msg_throttling_msger_v3", 1).

-record(statem_data, {coparty_id = undefined, trace = [], msgs = [], state_map = {}, delayable_sends = false}).

start_link() -> gen_statem:start_link({local, ?SERVER}, ?MODULE, [], []).

callback_mode() -> [state_functions, state_enter].

init([]) -> {ok, std_state1, {}}.

state1_std(enter, _OldState,
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = _Queue, options = _Options} = _Data) ->
    keep_state_and_data;
state1_std(internal, {send_msg1, Msg1}, Data) -> {next_state, recv_after_state2, Data}.

state2_recv_after(enter, _OldState, Data) ->
    io:format("(~p ->.)\n", [state2_recv_after]),
    {keep_state, Data, [{state_timeout, 3000, std_state3}]};
state2_recv_after(enter, _OldState,
                  #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [_H], options = _Options} = _Data) ->
    printout("(->) ~p, queued actions.", [{tree, variable, {attr, 0, [], none}, '?FUNCTION_NAME'}]),
    {keep_state_and_data, [{state_timeout, 0, process_queue}]};
state2_recv_after(enter, _OldState,
                  #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [], options = _Options} = _Data) ->
    printout("(->) ~p.", [{tree, variable, {attr, 0, [], none}, '?FUNCTION_NAME'}]),
    keep_state_and_data;
state2_recv_after(cast, {receive_ack1, Ack1}, Data) -> {next_state, std_state1, Data};
%% This is a timeout branch:
state2_recv_after(state_timeout, std_state3, Data) ->
    io:format("(timeout[~p] -> ~p.)\n", [3000, std_state3]),
    {next_state, std_state3, Data}.

state3_std(enter, _OldState,
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = _Queue, options = _Options} = _Data) ->
    keep_state_and_data;
state3_std(internal, {send_msg2, Msg2}, Data) -> {next_state, recv_after_state4, Data}.

state4_recv_after(enter, _OldState, Data) ->
    io:format("(~p ->.)\n", [state4_recv_after]),
    {keep_state, Data, [{state_timeout, 3000, std_state5}]};
state4_recv_after(enter, _OldState,
                  #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [_H], options = _Options} = _Data) ->
    printout("(->) ~p, queued actions.", [{tree, variable, {attr, 0, [], none}, '?FUNCTION_NAME'}]),
    {keep_state_and_data, [{state_timeout, 0, process_queue}]};
state4_recv_after(enter, _OldState,
                  #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = [], options = _Options} = _Data) ->
    printout("(->) ~p.", [{tree, variable, {attr, 0, [], none}, '?FUNCTION_NAME'}]),
    keep_state_and_data;
state4_recv_after(cast, {receive_ack2, Ack2}, Data) -> {next_state, recv_after_state2, Data};
%% This is a timeout branch:
state4_recv_after(state_timeout, std_state5, Data) ->
    io:format("(timeout[~p] -> ~p.)\n", [3000, std_state5]),
    {next_state, std_state5, Data}.

state5_std(enter, _OldState,
           #statem_data{coparty_id = _CoPartyID, state_stack = _States, msg_stack = _Msgs, queued_actions = _Queue, options = _Options} = _Data) ->
    keep_state_and_data;
state5_std(internal, {send_tout, Tout}, Data) -> {next_state, custom_end_state, Data}.

custom_end_state(enter, _OldState, Data) ->
    io:format("(~p ->.)\n", [custom_end_state]),
    {keep_state, Data, [{state_timeout, 0, go_to_terminate}]};
custom_end_state(state_timeout, go_to_terminate, Data) -> {next_state, go_to_terminate, Data}.

terminate(_Reason, _State, _Data) -> ok.

receive_ack1(Ack1) -> gen_statem:cast(?SERVER, {receive_ack1, Ack1}).

receive_ack2(Ack2) -> gen_statem:cast(?SERVER, {receive_ack2, Ack2}).

send_msg1(Msg1) -> gen_statem:internal(?SERVER, {send_msg1, Msg1}).

send_msg2(Msg2) -> gen_statem:internal(?SERVER, {send_msg2, Msg2}).

send_tout(Tout) -> gen_statem:internal(?SERVER, {send_tout, Tout}).

stop() -> gen_statem:stop(?SERVER).