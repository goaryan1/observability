-module(mapf_util).

-include("src/butler_server.hrl").

-export(
    [
        make_key/2,
        north/1,
        north/2,
        east/1,
        east/2,
        south/1,
        south/2,
        west/1,
        west/2,
        convert_time/2,
        date_time/2,
        neighbour/2,
        neighbour/3,
        is_valid_neighbour/2,
        multiply/2,
        add/2,
        gt/2,
        gte/2,
        lt/2,
        lte/2,
        dir_data/2,
        turn_degree/3,
        make_turn_data/1,
        make_turn_data/2,
        orientation_degree/1,
        key_find/2,
        choose_from_number/1,
        choose_from_list/1,
        choose_and_delete/1,
        choose_n_from_list/2,
        choose_from_range/1,
        get_node/1,
        get_value/2,
        data_to_list/1,
        maps_take/2,
        get_padded_string_value/2,
        newline/0,
        mapf_log/3,
        mapf_log/4,
        set_lager_metadata/1,
        dump_mapf_log_messages/2,
        flush_mapf_log_messages/0,
        set_logging_config/1,
        set_config/2,
        get_mapf_message_count/0,
        is_direction_valid/1,
        persist_span_map/1,
        fetch_span_map/0,
        clear_span_map/0,
        debug_input/2,
        get_normal_liftstate_from_rack_dir/1,
        get_stop_duration/2,
        print_reservations_for_coordinate/1
    ]
).

-include("../../../../include/mapf.hrl").

% get_datatype(X) ->
%     case X of
%         _ when is_atom(X) -> atom;
%         _ when is_binary(X) -> binary;
%         _ when is_bitstring(X) -> bitstring;
%         _ when is_boolean(X) -> boolean;
%         _ when is_float(X) -> float;
%         _ when is_function(X) -> function;
%         _ when is_integer(X) -> integer;
%         _ when is_list(X) -> list;
%         _ when is_map(X) -> map;
%         _ when is_number(X) -> number;
%         _ when is_pid(X) -> pid;
%         _ when is_port(X) -> port;
%         _ when is_reference(X) -> reference;
%         _ when is_tuple(X) -> tuple;
%         _ -> unknown
%     end.

debug_helper(Var) ->
    Filename = "output_log",
    {ok, File} = file:open(Filename, [write, append]),
    io:format(File, "~p.~n", [Var]),
    file:close(File).

debug_map_handler(MapName, MapData) ->
    debug_helper(MapName),
    lists:foreach(
        fun(Key) ->
            case maps:find(Key, MapData) of
                {ok, Value} ->
                    % debug_helper({"Key", get_datatype(Key)}),
                    % debug_helper({"Value", get_datatype(Value)}),
                    debug_helper({Key, Value});
                error ->
                    ok
            end
        end,
        maps:keys(MapData)
    ).

debug_restable(Title, ResTable) ->
    debug_helper(Title),
    ResMapList = [
        {res_map, ResTable#reservation_table.res_map},
        {butler_map, ResTable#reservation_table.butler_map},
        {bidle_map, ResTable#reservation_table.bidle_map},
        {cidle_map, ResTable#reservation_table.cidle_map},
        {butler_unit_map, ResTable#reservation_table.butler_unit_map},
        {rack_unit_map, ResTable#reservation_table.rack_unit_map}
    ],
    lists:foreach(
        fun(Map) ->
            {MapName, MapData} = Map,
            debug_map_handler(MapName, MapData)
        end,
        ResMapList
    ),
    ok.

-spec make_key(V1 :: term(), V2 :: term()) -> term().
make_key(V1, V2) ->
    {V1, V2}.

-spec north({X :: integer(), Y :: integer()}, NSteps :: integer()) -> {integer(), integer()}.
north({X, Y}, NSteps) ->
    {X, Y - NSteps}.

-spec east({X :: integer(), Y :: integer()}, NSteps :: integer()) -> {integer(), integer()}.
east({X, Y}, NSteps) ->
    {X - NSteps, Y}.

-spec south({X :: integer(), Y :: integer()}, NSteps :: integer()) -> {integer(), integer()}.
south({X, Y}, NSteps) ->
    {X, Y + NSteps}.

-spec west({X :: integer(), Y :: integer()}, NSteps :: integer()) -> {integer(), integer()}.
west({X, Y}, NSteps) ->
    {X + NSteps, Y}.

-spec north({X :: integer(), Y :: integer()}) -> {integer(), integer()}.
north({X, Y}) ->
    north({X, Y}, 1).

-spec east({X :: integer(), Y :: integer()}) -> {integer(), integer()}.
east({X, Y}) ->
    east({X, Y}, 1).

-spec south({X :: integer(), Y :: integer()}) -> {integer(), integer()}.
south({X, Y}) ->
    south({X, Y}, 1).

-spec west({X :: integer(), Y :: integer()}) -> {integer(), integer()}.
west({X, Y}) ->
    west({X, Y}, 1).

-spec neighbour(
    Dir :: ?NORTH | ?EAST | ?SOUTH | ?WEST, {X :: integer(), Y :: integer()}, NSteps :: integer()
) -> {integer(), integer()}.
neighbour(?CFG_NORTH, {X, Y}, NSteps) ->
    north({X, Y}, NSteps);
neighbour(?CFG_EAST, {X, Y}, NSteps) ->
    east({X, Y}, NSteps);
neighbour(?CFG_SOUTH, {X, Y}, NSteps) ->
    south({X, Y}, NSteps);
neighbour(?CFG_WEST, {X, Y}, NSteps) ->
    west({X, Y}, NSteps).

-spec neighbour(Dir :: ?NORTH | ?EAST | ?SOUTH | ?WEST, {X :: integer(), Y :: integer()}) ->
    {integer(), integer()}.
neighbour(Dir, {X, Y}) ->
    neighbour(Dir, {X, Y}, 1).

-spec multiply(N1 :: integer() | ?INFINITY, N2 :: integer() | ?INFINITY) -> integer() | ?INFINITY.
multiply(?INFINITY, _N2) ->
    ?INFINITY;
multiply(_N1, ?INFINITY) ->
    ?INFINITY;
multiply(N1, N2) ->
    N1 * N2.

-spec add(N1 :: integer() | ?INFINITY, N2 :: integer() | ?INFINITY) -> integer() | ?INFINITY.
add(?INFINITY, _N2) ->
    ?INFINITY;
add(_N1, ?INFINITY) ->
    ?INFINITY;
add(N1, N2) ->
    N1 + N2.

-spec gt(N1 :: integer() | ?INFINITY, N2 :: integer() | ?INFINITY) -> true | false.
gt(_N1, ?INFINITY) ->
    false;
gt(?INFINITY, _N2) ->
    true;
gt(N1, N2) ->
    N1 > N2.

-spec gte(N1 :: integer() | ?INFINITY, N2 :: integer() | ?INFINITY) -> true | false.
gte(?INFINITY, ?INFINITY) ->
    true;
gte(_N1, ?INFINITY) ->
    false;
gte(?INFINITY, _N2) ->
    true;
gte(N1, N2) ->
    N1 >= N2.

-spec lt(N1 :: integer() | ?INFINITY, N2 :: integer() | ?INFINITY) -> true | false.
lt(_N1, ?INFINITY) ->
    true;
lt(?INFINITY, _N2) ->
    false;
lt(N1, N2) ->
    N1 < N2.

-spec lte(N1 :: integer() | ?INFINITY, N2 :: integer() | ?INFINITY) -> true | false.
lte(?INFINITY, ?INFINITY) ->
    true;
lte(_N1, ?INFINITY) ->
    true;
lte(?INFINITY, _N2) ->
    false;
lte(N1, N2) ->
    N1 =< N2.

-spec orientation_degree(Orientation :: ?CLOCK_WISE | ?COUNTER_CLOCK_WISE) -> term().
orientation_degree(?CLOCK_WISE) ->
    ?D270;
orientation_degree(?COUNTER_CLOCK_WISE) ->
    ?D090.

-spec make_turn_data(IData :: term()) -> term().
make_turn_data({_BDir, ?UNDEFINED, NDir, ?UNDEFINED}) ->
    {NDir, ?UNDEFINED, NDir};
make_turn_data({BDir, RDir, ?UNDEFINED, EDir}) ->
    BVal1 = dir_data(RDir, EDir),
    BDir1 = dir_data(BDir, BVal1),
    {BDir1, EDir, BDir1};
make_turn_data({BDir, RDir, NDir, ?UNDEFINED}) ->
    BVal1 = dir_data(BDir, NDir),
    RDir1 = dir_data(RDir, BVal1),
    {NDir, RDir1, NDir};
make_turn_data({BDir, RDir, NDir, EDir}) ->
    BValue = dir_data(BDir, NDir),
    RValue = dir_data(RDir, EDir),
    case (BValue =/= ?D180 andalso BValue =:= RValue) of
        true ->
            {NDir, EDir, NDir};
        false ->
            case {BValue, RValue} of
                {?D180, _} ->
                    {NDir, RDir, NDir};
                {_, ?D180} ->
                    RDir1 = dir_data(RDir, BValue),
                    {NDir, RDir1, NDir};
                {_, _} ->
                    TDir = dir_data(BDir, RValue),
                    {NDir, EDir, TDir}
            end
    end.

-spec make_turn_data(
    IData :: term(),
    Dir :: ?UNDEFINED | ?CLOCK_WISE | ?COUNTER_CLOCK_WISE
) -> term().
make_turn_data(IData, ?UNDEFINED) ->
    make_turn_data(IData);
make_turn_data({_, ?UNDEFINED, _, _} = IData, _Dir) ->
    make_turn_data(IData);
make_turn_data({_, _, ?UNDEFINED, _} = IData, _Dir) ->
    make_turn_data(IData);
make_turn_data({BDir, RDir, NDir, _EDir} = IData, Orientation) ->
    case dir_data(BDir, RDir) of
        ?D000 ->
            make_turn_data(IData);
        ?D180 ->
            make_turn_data(IData);
        _ ->
            RDir1 = dir_data(RDir, dir_data(BDir, NDir)),
            {TDir2, RDir2} =
                case dir_data(NDir, RDir1) =:= orientation_degree(Orientation) of
                    true ->
                        {NDir, RDir1};
                    false ->
                        {dir_data(NDir, ?D180), dir_data(RDir1, ?D180)}
                end,
            {NDir, RDir2, TDir2}
    end.

-spec turn_degree(Dir1 :: term(), Dir2 :: term(), TurnRotate :: term()) -> term().
turn_degree(Dir1, Dir2, TurnRotate) ->
    case maps:find({{Dir1, Dir2}, TurnRotate}, ?DXMAP) of
        {ok, Value} ->
            Value;
        error ->
            0
    end.
-spec dir_data(Dir1 :: term(), DVal1 :: term()) -> term().
dir_data(Dir1, DVal1) ->
    case maps:find({Dir1, DVal1}, ?DDMAP) of
        {ok, Value} ->
            Value;
        error ->
            ?ERROR(
                "#COWHCA: #wrong_dir_case, function called with wrong direction input Dir1 = ~p, DVal1 = ~p, Stacktrace = ~p",
                [Dir1, DVal1, process_info(self(), current_stacktrace)]
            ),
            %% Using randon valid direction
            ?NORTH
    end.

-spec is_valid_neighbour(Dir :: ?NORTH | ?EAST | ?SOUTH | ?WEST, NList :: list()) -> true | false.
is_valid_neighbour(Dir, NList) ->
    lists:member(Dir, NList).

-spec convert_time(
    {FTimeUnit :: ?MINUTES | ?SECONDS | ?MILLISECONDS, Time :: integer() | {integer(), integer()}},
    TTimeUnit :: ?MINUTES | ?SECONDS | ?MILLISECONDS
) -> {?MINUTES | ?SECONDS | ?MILLISECONDS, integer() | {integer(), integer()}}.
convert_time({Unit1, {Time11, Time21}}, Unit2) ->
    {Unit2, Time12} = convert_time({Unit1, Time11}, Unit2),
    {Unit2, Time22} = convert_time({Unit1, Time21}, Unit2),
    {Unit2, {Time12, Time22}};
convert_time({Unit, Time}, Unit) ->
    {Unit, Time};
convert_time({?MINUTES, Time}, ?SECONDS) ->
    convert_time({?SECONDS, Time * 60}, ?SECONDS);
convert_time({?MINUTES, Time}, ?MILLISECONDS) ->
    convert_time(convert_time({?MINUTES, Time}, ?SECONDS), ?SECONDS);
convert_time({?SECONDS, Time}, ?MINUTES) ->
    convert_time({?MINUTES, Time div 60}, ?MINUTES);
convert_time({?SECONDS, Time}, ?MILLISECONDS) ->
    convert_time({?MILLISECONDS, Time * 1000}, ?MILLISECONDS);
convert_time({?MILLISECONDS, Time}, ?SECONDS) ->
    convert_time({?SECONDS, Time div 1000}, ?SECONDS);
convert_time({?MILLISECONDS, Time}, ?MINUTES) ->
    convert_time(convert_time({?MILLISECONDS, Time}, ?SECONDS), ?MINUTES).

-spec date_time(Time :: integer(), TimeMultiplier :: integer()) -> calendar:datetime().
date_time(Time, TimeMultiplier) ->
    calendar:gregorian_seconds_to_datetime(Time div TimeMultiplier).

-spec choose_from_list(List :: list()) -> term().
choose_from_list(List) ->
    N = rand:uniform(length(List)),
    lists:nth(N, List).

-spec choose_and_delete(List :: list()) -> {term(), list()}.
choose_and_delete(List) ->
    Elem = choose_from_list(List),
    {Elem, lists:delete(Elem, List)}.

-spec choose_n_from_list(N :: integer(), List :: list()) -> {list(), list()}.
choose_n_from_list(N, List) ->
    lists:foldl(
        fun(_, {TListX, SListX}) ->
            {ElemX, SListX1} = choose_and_delete(SListX),
            {[ElemX | TListX], SListX1}
        end,
        {[], List},
        lists:seq(1, N)
    ).

-spec choose_from_range({Min :: integer(), Max :: integer()}) -> integer().
choose_from_range({Min, Max}) ->
    rand:uniform(Max - Min + 1) + (Min - 1).

-spec choose_from_number(N :: integer()) -> integer().
choose_from_number(N) ->
    rand:uniform(N).

-spec get_node(Name :: atom()) -> atom().
get_node(Name) ->
    list_to_atom(
        atom_to_list(Name) ++
            lists:dropwhile(fun(X) -> X =/= $@ end, atom_to_list(node()))
    ).

-spec get_value(Value :: ?UNDEFINED | term(), DValue :: term()) -> term().
get_value(?UNDEFINED, DValue) ->
    DValue;
get_value(Value, _DValue) ->
    Value.

-spec data_to_list(Data :: term()) -> list().
data_to_list(Data) when is_list(Data) ->
    Data;
data_to_list(Data) when is_atom(Data) ->
    atom_to_list(Data);
data_to_list(Data) when is_integer(Data) ->
    integer_to_list(Data);
data_to_list(Data) when is_float(Data) ->
    float_to_list(Data);
data_to_list(Data) when is_binary(Data) ->
    binary_to_list(Data);
data_to_list(Data) when is_bitstring(Data) ->
    bitstring_to_list(Data).

-spec newline() -> term().
newline() ->
    io:fwrite("~n").

-spec key_find(Key :: term(), TupleList :: list()) -> term().
key_find(Key, TupleList) ->
    {_, Value} = lists:keyfind(Key, 1, TupleList),
    Value.

-spec maps_take(Key :: term(), Map :: maps:map()) -> error | {term(), maps:map()}.
maps_take(Key, Map) ->
    case maps:find(Key, Map) of
        error ->
            error;
        {ok, Value} ->
            {Value, maps:remove(Key, Map)}
    end.

-spec get_padded_string_value(Padding :: string(), Value :: non_neg_integer()) -> string().
get_padded_string_value(_Padding, Value) ->
    integer_to_list(Value).
%PaddedValue = Padding ++ integer_to_list(Value),
%lists:sublist(PaddedValue, (length(PaddedValue)-length(Padding)+1), length(Padding)).

-spec mapf_log(
    {LogLevelNum :: pos_integer(), LogLevel :: info | debug, Mod :: term()},
    LogArgs ::
        ?UNDEFINED
        | {AddNewLine :: boolean(), LogStringFormat :: string(), LogParams :: list()}
        | {LogStringFormat :: string(), LogParams :: list()},
    AppConfig :: #app_config{}
) -> term().

mapf_log({_LogLevelNum, _LogLevel, _Mod}, ?UNDEFINED, #app_config{}) ->
    ok;
mapf_log({LogLevelNum, LogLevel, Mod}, Args, #app_config{} = AppConfig) ->
    mapf_log_new({LogLevel, Mod}, Args, AppConfig),
    {CLogLevel, CModList} = app_config:get_mapf_log(AppConfig),
    mapf_log({LogLevelNum, LogLevel, Mod}, Args, CLogLevel, CModList).

-spec mapf_log(
    {LogLevelNum :: pos_integer(), LogLevel :: info | debug, Mod :: term()},
    LogArgs ::
        ?UNDEFINED
        | {AddNewLine :: boolean(), LogStringFormat :: string(), LogParams :: list()}
        | {LogStringFormat :: string(), LogParams :: list()},
    CLogLevel :: integer(),
    CModList :: list()
) -> term().
mapf_log({LogLevelNum, _LogLevel, Mod}, Args, CLogLevel, CModList) ->
    case LogLevelNum =< CLogLevel andalso lists:member(Mod, CModList) of
        true ->
            {LogStringFormat, LogParams} =
                case Args of
                    {true, LogStringFormat1, LogParams1} ->
                        {"~n" ++ LogStringFormat1, LogParams1};
                    {false, LogStringFormat1, LogParams1} ->
                        {LogStringFormat1, LogParams1};
                    {LogStringFormat1, LogParams1} ->
                        {LogStringFormat1, LogParams1}
                end,
            path_calc_logger:debug("module=~p: " ++ LogStringFormat, [Mod | LogParams]);
        false ->
            ok
    end.

-spec mapf_log_new(
    {LogLevel :: info | debug, Mod :: term()},
    LogArgs ::
        {AddNewLine :: boolean(), LogStringFormat :: string(), LogParams :: list()}
        | {LogStringFormat :: string(), LogParams :: list()},
    AppConfig :: #app_config{}
) -> ok.
mapf_log_new({_LogLevel, Mod}, Args, #app_config{} = AppConfig) ->
    MapfLogConfig = app_config:get_mapf_log_new(AppConfig),
    IsEnabled = maps:get(enabled, MapfLogConfig, false),
    if
        IsEnabled =:= true ->
            % @todo Logging everything with log level debug.
            mapf_log_server:log(debug, Mod, Args);
        true ->
            ok
    end.

-spec set_lager_metadata(
    MetaData :: list({Key :: atom(), Value :: term()})
) -> ok.
set_lager_metadata(MetaData) ->
    logging_utils:lager_md(MetaData),
    mapf_log_server:set_lager_metadata(MetaData).

-spec dump_mapf_log_messages(
    MapfResult :: #mapf_path_calc_result{},
    AppConfig :: #app_config{}
) -> ok.
dump_mapf_log_messages(MapfResult, #app_config{} = AppConfig) ->
    MapfLogConfig = app_config:get_mapf_log_new(AppConfig),
    IsEnabled = maps:get(enabled, MapfLogConfig, false),
    if
        IsEnabled =:= true ->
            mapf_log_server:dump_messages(MapfResult);
        true ->
            ok
    end.

-spec flush_mapf_log_messages() -> ok.
flush_mapf_log_messages() ->
    mapf_log_server:flush_messages().

% @doc: sets path calculation logging level
-spec set_logging_config(LogLevel :: integer()) -> ok.
set_logging_config(LogLevel) ->
    {_Level, ModuleList} =
        application:get_env(
            butler_server,
            mapf_log,
            {0, [
                co_whca_process,
                co_whca_path_calc,
                co_whca_neighbour,
                co_whca_process_explicit,
                reservation_table_wt
            ]}
        ),
    application:set_env(butler_server, mapf_log, {LogLevel, ModuleList}),
    mapf_client:update_config_value(node(), mapf_log, {LogLevel, ModuleList}).

% @doc: sets path calculation logging level
-spec set_config(
    ConfigName :: term(),
    ConfigValue :: term()
) -> ok.
set_config(ConfigName, ConfigValue) ->
    application:set_env(butler_server, ConfigName, ConfigValue),
    mapf_client:update_config_value(node(), ConfigName, ConfigValue).

-spec get_mapf_message_count() -> MessageCountMap :: maps:map().
get_mapf_message_count() ->
    InitialMessageCountMap =
        #{
            path_calc => 0,
            position_update => 0,
            reservation_update => 0,
            other => 0
        },
    {messages, MessagesInQueue} = process_info(erlang:whereis(mapf_path_calculator), messages),
    lists:foldl(
        fun
            (
                {'$gen_cast', {?REQ_MAPF_PATH_CALC, _, _}},
                #{path_calc := PathCalcCount} = MessageCountMap
            ) ->
                MessageCountMap#{path_calc => PathCalcCount + 1};
            (
                {'$gen_cast', {?REQ_MAPF_MOVE_RACK, _}},
                #{position_update := PositionUpdateCount} = MessageCountMap
            ) ->
                MessageCountMap#{position_update => PositionUpdateCount + 1};
            (
                {'$gen_cast', {?REQ_MAPF_UPDATE_RESERVATION_TYPE, _}},
                #{reservation_update := ReservationUpdateCount} = MessageCountMap
            ) ->
                MessageCountMap#{reservation_update => ReservationUpdateCount + 1};
            (_, #{other := OtherCount} = MessageCountMap) ->
                MessageCountMap#{other => OtherCount + 1}
        end,
        InitialMessageCountMap,
        MessagesInQueue
    ).

is_direction_valid(Direction) ->
    lists:member(Direction, [0, 1, 2, 3]).

-spec persist_span_map(SpanMap :: maps:map()) -> any().
persist_span_map(SpanMap) ->
    case application:get_env(mhs, persist_span_map, false) of
        false ->
            ok;
        true ->
            DataDir = application:get_env(butler_server, data_dir, "."),
            File = filename:join([DataDir, "span_map.bin"]),
            %% Check if file already exists
            case filelib:is_regular(File) of
                true ->
                    ok;
                false ->
                    SpanMapBinary = erlang:term_to_binary(SpanMap),
                    file:write_file(File, SpanMapBinary)
            end
    end.

-spec fetch_span_map() -> maps:map() | error.
fetch_span_map() ->
    DataDir = application:get_env(butler_server, data_dir, "."),
    File = filename:join([DataDir, "span_map.bin"]),
    case filelib:is_regular(File) of
        false ->
            error;
        true ->
            {ok, SpanMapBinary} = file:read_file(File),
            erlang:binary_to_term(SpanMapBinary)
    end.

-spec clear_span_map() -> any().
clear_span_map() ->
    DataDir = application:get_env(butler_server, data_dir, "."),
    File = filename:join([DataDir, "span_map.bin"]),
    file:delete(File).

-spec debug_input(StaticInputFilename :: string(), PathCalcInputFilename :: string()) -> none().
debug_input(StaticInputFilename, PathCalcInputFilename) ->
    %% turn on persist_input_to_debug using
    %% mapf_client:persist_input_to_debug(node(), true, 20000, [300])
    %% this will generate input files to debug
    %% pass them to mapf_util:debug_input
    {ok, StaticFileContent} = file:read_file(StaticInputFilename),
    {GridLayout, AppConfig0} = erlang:binary_to_term(StaticFileContent),
    {ok, FileContent} = file:read_file(PathCalcInputFilename),
    {
        {ButlerId, RackId, ButlerType, LiftState, Options},
        {StartCoor, {ButlerDir, RackDir}},
        {EndCoor, EndDir},
        StartTime,
        #reservation_table{} = ResTable0,
        {HeuristicsInfo, ButlerMovementInfo, RackInfo, VisitedNodeMap},
        LastWindowEndNode,
        ReservedPath,
        RemainingPath,
        ButlerMoveStatus
    } = erlang:binary_to_term(FileContent),
    AppConfig1 = app_config:set_mapf_debug_mode(true, AppConfig0),
    Result = co_whca_path_calc:path_calc({
        {ButlerId, RackId, ButlerType, LiftState, Options},
        {StartCoor, {ButlerDir, RackDir}},
        {EndCoor, EndDir},
        StartTime,
        #reservation_table{} = ResTable0,
        AppConfig1,
        {GridLayout, HeuristicsInfo, ButlerMovementInfo, RackInfo, VisitedNodeMap},
        LastWindowEndNode,
        ReservedPath,
        RemainingPath,
        ButlerMoveStatus
    }),
    #mapf_path_calc_result{
        result_tag = ResultTag1,
        lift_state = _LiftState1,
        msg_ref = _MsgRef1,
        path_list = _PathList1,
        open_node = _OpenNode1,
        start_coor = StartCoor1,
        start_time = _StartTime1,
        end_coor = _EndCoor1,
        end_dir = _EndDir1,
        idle_list = _IdleList1,
        is_destination_coordinate_in_idle_butler_map = _IsDestinationInIdleMap1,
        error_reason = _ErrorReason1,
        error_value = _ErrorValue1,
        old_path = _OldPath1,
        path_calculation_data = _PathCalcData1
    } = Result,
    {_SeqNo1, ResTable1, Result1} = reservation_table:update(
        {?UNDEFINED, 1}, {ButlerId, ButlerDir}, Result, AppConfig1, GridLayout, ResTable0, Options
    ),
    #mapf_path_calc_result{path_list = PathList2} = Result1,
    io:format(
        "StartTime ~p~n"
        "Source ~p~n"
        "Destination ~p~n"
        "Resulter ~p~n"
        "Path ~p~n",
        [StartTime, StartCoor1, EndCoor, ResultTag1, PathList2]
    ),
    ok.

-spec get_normal_liftstate_from_rack_dir(RackDir :: ?UNDEFINED | mapf_direction()) -> up | down.
get_normal_liftstate_from_rack_dir(?UNDEFINED) ->
    down;
get_normal_liftstate_from_rack_dir(_RackDir) ->
    up.

%% Possible goal types supported: <<"store_io_point">>, <<"deadlock_resolution_point">>
-spec get_stop_duration(
    GoalType :: binary(),
    AppConfig :: app_config()
) -> number().
get_stop_duration(GoalType, AppConfig) ->
    StopDurationMap = app_config:get_stop_duration(AppConfig),
    maps:get(GoalType, StopDurationMap, 3600000).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_timed_reservations(Coordinate, ResMap) ->
    Fun = fun(Coord, CoordResMap) ->
        case Coord of
            Coordinate ->
                CoordResMap1 = maps:map(
                    fun(Butler, Value, _) ->
                        ButlerResList = lists:map(
                            fun({_, _, _, StartTime, EndTime}) ->
                                {Butler, StartTime, EndTime}
                            end,
                            Value
                        ),
                        ButlerResList
                    end,
                    CoordResMap
                ),
                CoordResMap1;
            _ ->
                ok
        end
    end,
    FilteredResMap = maps:map(Fun, ResMap),
    FilteredResMap.

get_idle_reservations(Coordinate, BidleMap) ->
    Fun = fun(_Butler, Value) ->
        IdleList = Value#reservation_idle_data.idle_list,
        NewList = lists:map(
            fun({_, Coord, StartTime}) ->
                case Coord == Coordinate of
                    true ->
                        {StartTime};
                    false ->
                        ok
                end
            end,
            IdleList
        ),
        NewList
    end,
    FilteredBidleMap = maps:map(Fun, BidleMap),
    FilteredBidleMap1 = maps:filtermap(
        fun(_Key, Value) ->
            Value /= [ok]
        end,
        FilteredBidleMap
    ),
    FilteredBidleMap1,
    ResultList = [
        {Key, X}
     || {Key, TupleList} <- maps:to_list(FilteredBidleMap1), {X} <- TupleList
    ],
    ResultList.

-spec print_reservations_for_coordinate_helper(
    Coordinate :: {X :: integer(), Y :: integer()},
    ResTable :: reservation_table()
) -> ok.
print_reservations_for_coordinate_helper(Coordinate, ResTable) ->
    #reservation_table{
        res_map = ResMap,
        butler_map = _ButlerMap,
        bidle_map = BidleMap,
        cidle_map = _CIdleMap,
        butler_unit_map = _ButlerUnitMap,
        rack_unit_map = _RackUnitMap
    } = ResTable,
    io:format("Reservation Data for ~p~n", [Coordinate]),

    % io:format("Bidle Map:\n~p\n", [BidleMap]),
    % io:format("Res Map:\n~p\n", [ResMap]),

    % timed reservations
    FilteredResMap = get_timed_reservations(Coordinate, ResMap),
    io:format("FilteredResMap: ~p\n", [FilteredResMap]),

    % idle reservations
    IdleResList = get_idle_reservations(Coordinate, BidleMap),
    io:format("FilteredBidleMap: ~p\n", [IdleResList]).

print_reservations_for_coordinate(Coordinate) ->
    PathCalcInputFilename =
        "/tmp/cowhca-debug-input-1713426651562/path-calc-input-300-1713426654879.txt",
    {ok, FileContent} = file:read_file(PathCalcInputFilename),
    {_, _, _, _, #reservation_table{} = ResTable, _, _, _, _, _} = erlang:binary_to_term(
        FileContent
    ),
    print_reservations_for_coordinate_helper(Coordinate, ResTable).
