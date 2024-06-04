-module('advanced_mixed_choice_recv_first__ali_test.erl').

-file("advanced_mixed_choice_recv_first__ali_test.erl", 1).

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
    {Data1, _TID_t1} = set_timer(t1, 5000, Data),
    receive
        {CoParty, first, Payload_First} ->
            Data2 = save_msg(first, Payload_First, Data1),
            AwaitSelection = nonblocking_selection(fun select_state3/1, [], self(), t1),
            receive
                {AwaitSelection, ok, {Label, Payload}} ->
                    case Label of
                        second ->
                            Payload_Second = payload,
                            CoParty ! {self(), second, Payload_Second},
                            stopping(CoParty, Data3);
                        _ -> error(unexpected_label_selected)
                    end;
                {AwaitPayload, ko} ->
                    error(unspecified_error),
                    stopping(CoParty, Data6)
            end
        after 3000 ->
                  AwaitSelection = nonblocking_selection(fun select_state7/1, [], self(), t1),
                  receive
                      {AwaitSelection, ok, {Label, Payload}} ->
                          case Label of
                              second ->
                                  Payload_Second = payload,
                                  CoParty ! {self(), second, Payload_Second},
                                  stopping(CoParty, Data7);
                              _ -> error(unexpected_label_selected)
                          end;
                      {AwaitPayload, ko} ->
                          receive
                              {CoParty, third, Payload_Third} ->
                                  Data9 = save_msg(third, Payload_Third, Data7),
                                  stopping(CoParty, Data9)
                          end
                  end
    end.

%% @doc Adds default reason 'normal' for stopping.
%% @see stopping/3.
stopping(CoParty, Data) -> stopping(normal, CoParty, Data).

%% @doc Adds default reason 'normal' for stopping.
%% @param Reason is either atom like 'normal' or tuple like {error, more_details_or_data}.
stopping(normal = _Reason, _CoParty, _Data) -> exit(normal);
%% @doc stopping with error.
%% @param Reason is either atom like 'normal' or tuple like {error, Reason, Details}.
%% @param CoParty is the process ID of the other party in this binary session.
%% @param Data is a list to store data inside to be used throughout the program.
stopping({error, Reason, Details}, _CoParty, _Data) when is_atom(Reason) -> erlang:error(Reason, Details);
%% @doc Adds default Details to error.
stopping({error, Reason}, CoParty, Data) when is_atom(Reason) -> stopping({error, Reason, []}, CoParty, Data);
%% @doc stopping with Unexpected Reason.
stopping(Reason, _CoParty, _Data) when is_atom(Reason) -> exit(Reason).

select_state3([]) -> second;
select_state3(_Selection) -> expand_this_stub.

get_state3_payload() -> ok.

select_state7([]) -> second;
select_state7(_Selection) -> expand_this_stub.

get_state7_payload() -> ok.