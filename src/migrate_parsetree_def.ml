(** Errors that can happen when converting constructions that doesn't exist in
    older version of the AST. *)
type missing_feature =
  | Pexp_letexception
    (** 4.04 -> 4.03: local exception, let exception _ in ... *)
  | Ppat_open
    (** 4.04 -> 4.03: module open in pattern match x with M.(_) -> ... *)
  | Pexp_unreachable
    (** 4.04 -> 4.03: unreachable pattern -> . *)
  | PSig
    (** 4.03 -> 4.02: signature in attribute, [@: val x : int] *)
  | Pcstr_record
    (** 4.03 -> 4.02: inline record *)
  | Pconst_integer
    (** 4.03 -> 4.02: integer literal with invalid suffix, 1234d *)
  | Pconst_float
    (** 4.03 -> 4.02: float literal with invalid suffix, 1234.0g *)

exception Migration_error of missing_feature * Location.t

(** [missing_feature_description x] is a text describing the feature [x]. *)
let missing_feature_description = function
  | Pexp_letexception -> "local exceptions"
  | Ppat_open         -> "module open in patterns"
  | Pexp_unreachable  -> "unreachable patterns"
  | PSig              -> "signatures in attribute"
  | Pcstr_record      -> "inline records"
  | Pconst_integer    -> "custom integer literals"
  | Pconst_float      -> "custom float literals"

(** [missing_feature_minimal_version x] is the OCaml version where x was
    introduced. *)
let missing_feature_minimal_version = function
  | Pexp_letexception -> "OCaml 4.04"
  | Ppat_open         -> "OCaml 4.04"
  | Pexp_unreachable  -> "OCaml 4.03"
  | PSig              -> "OCaml 4.03"
  | Pcstr_record      -> "OCaml 4.03"
  | Pconst_integer    -> "OCaml 4.03"
  | Pconst_float      -> "OCaml 4.03"

(** Turn a missing feature into a reasonable error message. *)
let migration_error_message x =
  let feature = missing_feature_description x in
  let version = missing_feature_minimal_version x in
  feature ^ " are not supported before OCaml " ^ version

let () =
  let location_prefix l =
    if l = Location.none then "" else
      let {Location.loc_start; loc_end; _} = l in
      let bol = loc_start.Lexing.pos_bol in
      Printf.sprintf "File %S, line %d, characters %d-%d: "
        loc_start.Lexing.pos_fname
        loc_start.Lexing.pos_lnum
        (loc_start.Lexing.pos_cnum - bol)
        (loc_end.Lexing.pos_cnum - bol)
  in
  Printexc.register_printer (function
      | Migration_error (err, loc) ->
          Some (location_prefix loc ^ migration_error_message err)
      | _ -> None
    )
