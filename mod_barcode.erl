%   Copyright 2015 Daniel Hedeblom
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%       http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.

-module(mod_barcode).
-author("Daniel Hedeblom <maxifoo@gmail.com>").
-mod_title("Barcode Generator").
-mod_description("Generates Barcodes from PostScript").
-mod_prio(100).
-mod_schema(1).

-include_lib("zotonic.hrl").

-record(state, {context}).
-export([init/1]).

-export([
	 replace_underscore/2,
	 manage_schema/2,
	 gen_barcode/4,
	 observe_rsc_update_done/2
]).

%%%%
%%%% Init
%%%%
init(Context) ->
    case m_config:get_value(mod_barcode, barcode_ps_dir, Context) of
	undefined ->
	    m_config:set_value(mod_barcode, barcode_ps_dir, "../postscriptbarcode/build/monolithic", Context);
	_ -> ok
    end,

    case m_config:get_value(mod_barcode, barcode_convert_params, Context) of
	undefined ->
	    m_config:set_value(mod_barcode, barcode_convert_params, "-antialias -density 288x288 -trim +repage", Context);
	_ -> ok
    end,

    {ok, #state{context=Context}}.


%%%%
%%%% Installation
%%%%
manage_schema(install, _Context) ->
    #datamodel{categories=categories(),
               predicates=predicates(),
               resources=resources()
              }.

categories() ->
    [{barcode_type,meta,[{title, <<"Barcode Type">>}]}].

predicates() ->
    [{autocreate_barcode_type,[{title, <<"Autocreate Barcode">>}],[{category, barcode_type}]}].

resources() ->
    [
     {qrcode, barcode_type, [{title, <<"QR Code">>}]},
     {code93, barcode_type, [{title, <<"Code 93">>}]},
     {code39, barcode_type, [{title, <<"Code 39">>}]},
     {gs1_128composite, barcode_type, [{title, <<"GS1-128 Composite">>}]},
     {interleaved2of5, barcode_type, [{title, <<"Interleaved 2 of 5">>}]},
     {databartruncated, barcode_type, [{title, <<"DataBar Truncated">>}]},
     {databarstacked, barcode_type, [{title, <<"DataBar Stacked">>}]},
     {databarlimited, barcode_type, [{title, <<"DataBar Limited">>}]},
     {databarexpanded, barcode_type, [{title, <<"DataBar Expanded">>}]},
     {pharmacode, barcode_type, [{title, <<"Pharmacode">>}]},
     {code2of5, barcode_type, [{title, <<"Code 2 of 5">>}]},
     {code11, barcode_type, [{title, <<"Code 11">>}]},
     {rationalizedCodabar, barcode_type, [{title, <<"Rationalized Codabar">>}]},
     {ean13, barcode_type, [{title, <<"EAN-13">>}]},
     {ean8, barcode_type, [{title, <<"EAN-8">>}]},
     {upca, barcode_type, [{title, <<"UPC-A">>}]},
     {upce, barcode_type, [{title, <<"UPC-E">>}]},
     {isbn, barcode_type, [{title, <<"ISBN">>}]},
     {onecode, barcode_type, [{title, <<"OneCode">>}]},
     {postnet, barcode_type, [{title, <<"Postnet">>}]},
     {royalmail, barcode_type, [{title, <<"Royal Mail">>}]},
     {kix, barcode_type, [{title, <<"KIX">>}]},
     {japanpost, barcode_type, [{title, <<"JapanPost">>}]},
     {auspost, barcode_type, [{title, <<"AusPost">>}]},
     {msi, barcode_type, [{title, <<"MSI">>}]},
     {plessey, barcode_type, [{title, <<"Plessey">>}]},
     {itf14, barcode_type, [{title, <<"ITF-14">>}]},
     {maxicode, barcode_type, [{title, <<"MaxiCode">>}]},
     {pdf417, barcode_type, [{title, <<"PDF417">>}]},
     {datamatrix, barcode_type, [{title, <<"Data Matrix">>}]},
     {azteccode, barcode_type, [{title, <<"Aztec Code">>}]}
     ].
    

%%%%
%%%% When Update, Autocreate Barcodes
%%%%
observe_rsc_update_done(#rsc_update_done{action=insert, id=Id, pre_props=Prev, post_props=_Post }, Context) ->

    CatId = proplists:get_value(category_id,Prev),

    BarCodeTypes = m_edge:objects(CatId, autocreate_barcode_type, Context),

    %?zInfo(io_lib:format("Autocreate Barcode of types: ~p",[BarCodeTypes]),Context),
    %

    autocreate(BarCodeTypes, Id, Context);

observe_rsc_update_done(_,_) ->
    undefined.

%%%%
%%%% Some function for cleaning up a list of binaries [<<"hello">>, <<"world!\n">>] -> "helloworld"
%%%%
cleanup(<<Tail/binary>>) ->
    cleanup(Tail, []).

cleanup(<<Char:1/binary, Tail/binary>>, Clean) ->
    case re:run(Char, "[\"'`'^*a-zA-Z0-9-+&$:./()?#% ]", [global]) of
	{match, [[{0,1}]]} ->
	    cleanup(Tail, [Clean | binary_to_list(Char)]);
	nomatch ->
	    cleanup(Tail, [Clean]);
	_ ->
	    cleanup(Tail, [Clean])
    end;
cleanup(<<>>, Clean) ->
    lists:flatten(Clean).

glue_binaries([<<>> | Tail]) ->
    glue_binaries(Tail, []);

glue_binaries([First | Tail]) ->
    glue_binaries(Tail, cleanup(First)).

glue_binaries([First | Tail], Build) ->
    glue_binaries(Tail, [Build | cleanup(First)]);

glue_binaries([], Build) ->
    lists:flatten(Build).


%%%%
%%%% The autocreate function used by observe_rsc_update_done
%%%%
autocreate([BarCodeId|Rest], Id, Context) when is_integer(BarCodeId) ->
    TmpFile = z_tempfile:new(),

    BarCodeTypeString = binary_to_list(proplists:get_value(name, m_rsc:get(BarCodeId,Context))),
    BarCodeType=list_to_atom(BarCodeTypeString),

    BarcodeContent = case get_barcode_data(Id, BarCodeTypeString, Context) of
			 {ok, Content} ->
			     Content;
			 {error} ->
			     Id; %% If no data is found, just use the Id of the resource
			 _ ->
			     Id
		     end,

    case gen_barcode(BarcodeContent, BarCodeType, TmpFile, Context) of
	[] -> %returns an empty list means ok.
	    Data = file:read_file(TmpFile),
	    case m_media:insert_file(#upload{filename=TmpFile, data=Data, tmpfile=TmpFile, mime="image/png"},Context) of
		{ok, ObjId} ->
		    m_edge:insert(Id, depiction, ObjId, Context),
		    m_rsc:update(ObjId, [{barcode_type, BarCodeTypeString}, {barcode_autocreated, true}], Context),
		    ok;
		Err -> ?zWarning(io_lib:format("Create barcode error ~p~n",[{barcode_error, Err}]),Context),
		       error
	    end;
	Err ->
	    ?zWarning(io_lib:format("Create barcode error ~p~n",[{barcode_error, Err}]),Context),
	    error
    end,
    autocreate(Rest, Id, Context);

autocreate([], _Id, _Context) ->
    ok.

%%%%
%%%% Get barcode data by template (testing version)
%%%%
get_barcode_data(Id, Type, Context) ->
    Template = case Type of
		   [] ->
		       "barcode.tpl";
		   TypeName ->
		       lists:flatten([[["barcode."]|TypeName]|".tpl"])
	       end,

    case z_template:find_template(Template, Context) of
	{ok, _} ->
	    ContextQAll = lists:flatten([ [{id, Id}] | z_context:get_all(Context)]),
	    Out = lists:flatten(z_template:render(Template, ContextQAll,Context)),
	    {ok, glue_binaries(Out)};
	{error, _} ->
	    {error}
    end.


%%%%
%%%% Generate Barcode function
%%%%
to_list(Dir) when is_binary(Dir) ->
    binary_to_list(Dir);
to_list(Dir) when is_list(Dir) ->
    Dir.

replace_underscore([Letter|Tail], New) ->
    NewLetter = case Letter of
		    $_ ->
			$-;
		    _ ->
			Letter
		end,
    replace_underscore(Tail, [New|[NewLetter]]);

replace_underscore([], New) ->
    lists:flatten(New).

exec_command(A, TmpFile, Context) ->
    Dir = to_list(m_config:get_value(mod_barcode, barcode_ps_dir, Context)),
    ConvertParams = to_list(m_config:get_value(mod_barcode, barcode_convert_params, Context)),
    os:cmd([[[[[[[[[["cat <<EOF | cat "]|Dir]|"/barcode.ps - | convert "]|ConvertParams]|" - png:"]|TmpFile]|"\n"]|A]]|"\nEOF"]).

gen_barcode(Data, Type, TmpFile, Context) when is_atom(Type) and is_list(Data) and is_list(TmpFile) ->
    case m_rsc:get(Type, Context) of
	undefined ->
	    {undefined, Type};
	Resource ->
	    Title = proplists:get_value(title, Resource),
	    TypeName = binary_to_list(z_trans:trans(Title, Context)),
	    TypeFun = replace_underscore(atom_to_list(Type), []),
	    %?zInfo(io_lib:format("Create Barcode...~p",[TypeName]),Context),
	    exec_command(lists:flatten([[[[[[["/Helvetica findfont 10 scalefont setfont\n30 700 moveto ("]|Data]|") (includecheck includetext) /"]|TypeFun] |"/uk.co.terryburton.bwipp findresource exec\n0 -17 rmoveto ("]|TypeName]|") show\n\nshowpage"]), TmpFile, Context)
    end;

gen_barcode(Data, Type, TmpFile, Context) when is_integer(Data) ->
    gen_barcode(integer_to_list(Data), Type, TmpFile, Context);

gen_barcode(Data, Type, TmpFile, Context) when is_binary(Data) ->
    gen_barcode(binary_to_list(Data), Type, TmpFile, Context);

gen_barcode(Data, Type, TmpFile, Context) when is_list(Type) ->
    gen_barcode(Data, list_to_atom(Type), TmpFile, Context);

gen_barcode(_,_,_,_) -> undefined.

