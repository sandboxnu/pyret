declare const __pyret_module_return: unique symbol;
type ret = { [__pyret_module_return]: void };

declare const __pyret_value: symbol;
type val = { [__pyret_value]: void };

declare const __pyret_type: unique symbol;
type typ = { [__pyret_type]: void };

type todo = unknown;
type todo_func = (...args: todo[]) => todo;

type pyret_pos = {
  startRow: number;
  startCol: number;
  startChar: number;
  endRow: number;
  endChar: number;
};

interface PyretFFI {
  makePyretPos(filename: string, p: pyret_pos): val;
  combinePyretPos(filename: string, p1: pyret_pos, p2: pyret_pos): val;

  // #region throw
  throwUpdateNonObj(loc: val, objval: val, objloc: todo): never;
  throwUpdateFrozenRef(
    loc: val,
    objloc: val,
    fieldname: string,
    fieldloc: val,
  ): never;
  throwUpdateNonRef: todo_func;
  throwUpdateNonExistentField: todo_func;
  throwNumStringBinopError: todo_func;
  throwNumericBinopError: todo_func;
  throwInternalError: todo_func;
  throwSpinnakerError: todo_func;
  throwFieldNotFound: todo_func;
  throwConstructorSyntaxNonConstructor: todo_func;
  throwLookupConstructorNotObject: todo_func;
  throwLookupNonObject: todo_func;
  throwLookupNonTuple: todo_func;
  throwBadTupleBind: todo_func;
  throwNonTupleBind: todo_func;
  throwLookupLargeIndex: todo_func;
  throwExtendNonObject: todo_func;
  throwTypeMismatch: todo_func;
  throwInvalidArrayIndex: todo_func;
  throwMessageException(msg: string): never;
  throwMultiErrorException: todo_func;
  throwUserException: todo_func;
  throwEqualityException: todo_func;
  throwUninitializedId: todo_func;
  throwUninitializedIdMkLoc: todo_func;
  throwArityError: todo_func;
  throwArityErrorC: todo_func;
  throwHeaderRowMismatch: todo_func;
  throwRowLengthMismatch: todo_func;
  throwColLengthMismatch: todo_func;
  throwConstructorArityErrorC: todo_func;
  throwCasesArityError: todo_func;
  throwCasesArityErrorC: todo_func;
  throwCasesSingletonError: todo_func;
  throwCasesSingletonErrorC: todo_func;
  throwNonBooleanCondition: todo_func;
  throwNonBooleanOp: todo_func;
  throwNoBranchesMatched: todo_func;
  throwNoCasesMatched: todo_func;
  throwNonFunApp: todo_func;
  throwColumnNotFound: todo_func;
  throwDuplicateColumn: todo_func;
  throwUnfinishedTemplate: todo_func;
  throwModuleLoadFailureL: todo_func;
  throwParseErrorBadApp: todo_func;
  throwParseErrorBadFunHeader: todo_func;
  throwParseErrorNextToken: todo_func;
  throwParseErrorColonColon: todo_func;
  throwParseErrorEOF: todo_func;
  throwParseErrorUnterminatedString: todo_func;
  throwParseErrorBadNumber: todo_func;
  throwParseErrorBadOper: todo_func;
  throwParseErrorBadCheckOper: todo_func;
  // #endregion

  makeBadBracketException: todo_func;
  makeRecordFieldsFail: todo_func;
  makeTupleAnnsFail: todo_func;
  makeFieldFailure: todo_func;
  makeAnnFailure: todo_func;
  makeMissingField: todo_func;
  makeTupleLengthMismatch: todo_func;
  makeTypeMismatch: todo_func;
  makeRefInitFail: todo_func;
  makePredicateFailure: todo_func;
  makeDotAnnNotPresent: todo_func;
  makeFailureAtArg: todo_func;
  contractOk: todo;
  contractFail: todo;
  contractFailArg: todo;
  isOk: todo;
  isFail: todo;
  isFailArg: todo;

  equal: val;
  notEqual: val;
  unknown: val;
  isEqual(v: val): boolean;
  isNotEqual(v: val): boolean;
  isUnknown(v: val): boolean;
  isEqualityResult(v: val): boolean;

  makeInternalError(message: string, otherArgs: val): val;
  makeMessageException(message: string): val;
  makeUserException(val: val): val;
  makeModuleLoadFailureL(names: string[]): val;

  cases(
    pred: (val: val) => boolean,
    predName: string,
    val: val,
    casesObj: Record<string, func>,
  ): val;
  checkArity: PyretRuntime["checkArity"];

  makeList(items: val[]): val;
  isList(val: val): boolean;
  isLink(val: val): boolean;
  isEmpty(val: val): boolean;
  listLength(val: val): number;

  toArray(val: val): val[];

  isOption: (val: val) => boolean;
  isSome: (val: val) => boolean;
  isNone: (val: val) => boolean;
  makeSome(val: val): val;
  makeNone: () => val;

  isEither: (val: val) => boolean;
  isLeft: (val: val) => boolean;
  isRight: (val: val) => boolean;
  makeLeft(val: val): val;
  makeRight(val: val): val;
}

declare const __type_brander__: unique symbol;

type SrcLocJs =
  | [builtInModule: string]
  | [
      source: string,
      startLine: number,
      startColumn: number,
      startChar: number,
      endLine: number,
      endColumn: number,
      endChar: number,
    ];
type func = (...args: any[]) => any;

type restarter = {
  resume: (val: val) => void;
  // TODO:
  break: func;
  error: func;
};

type Resumer = (restarter: restarter) => void;

declare namespace ABI {
  class PBase {
    protected constructor();
    brands: Record<string, Boolean>;
    dict: Record<string, PBase>;

    extendWith(fields: Record<string, PBase>): PBase;
  }

  class POpaque extends PBase {}

  class PNothing extends PBase {
    brand(b: string): PNothing;
  }

  class PFunction extends PBase {
    protected constructor(fun: func, arity: number, name: string);
    app: func;
    name: number;

    brand(b: string): PFunction;
  }

  class PMethod extends PBase {
    protected constructor(meth: func, full_meth: func, name: string);
    meth: func;
    full_meth: func;
    name: string;
  }

  const enum RefState {
    GRAPHABLE = 0,
    UNGRAPHABLE = 1,
    SET = 2,
    FROZEN = 3,
  }

  class PRef {
    state: RefState;
    // TODO:
    anns: unknown[];
    value: unknown;
  }

  class PTuple extends PBase {
    vals: val[];
  }

  class SuccessResult {
    result: PBase;
    stats: unknown | undefined;
  }

  type __ErrorExt = {
    pyretStack?: string[];
    exn?: val;
  }

  class FailureResult {
    exn: Error & __ErrorExt;
    stats: unknown | undefined;
  }
}

type PyretObject = val & ABI.PBase;
type PyretOpaque = val & ABI.POpaque;
type PyretNothing = val & ABI.PNothing;
type PyretString = val & string;
type PyretBoolean = val & boolean;
type PyretRoughNum = val & number;

type PyretFunction = val & ABI.PFunction;
type PyretMethod = val & ABI.PMethod;

type PyretTuple = val & ABI.PTuple;

// TODO:
type RunOptions = {
  sync: boolean;
  initialGas: number;
  initialRunGas: number;
};


// NOTE: this is far from complete
interface PyretRuntime {
  builtins: val;
  run(
    program: unknown,
    namespace: unknown,
    options: RunOptions,
    onDone: unknown,
  ): unknown;
  runThunk<T, U>(
    f: () => T,
    then: (result: T) => unknown,
    options?: RunOptions,
  ): void;
  safeCall<T, U>(fun: () => T, after: (result: T) => U, stackFrame: string): U;

  ffi: PyretFFI;

  pauseStack(resumer: Resumer): val;
  schedulePause(resumer: Resumer): void;
  breakAll(): void;
  await<T>(promise: Promise<T>): T;

  getField<T>(obj: val, field: string): T;
  getFieldLoc<T>(obj: val, field: string, loc: SrcLocJs): T;
  getFieldRef<T>(obj: val, field: string, loc: SrcLocJs): T;
  getFields(obj: val): string[];
  getBracket<T>(loc: SrcLocJs, obj: val, field: string): T;
  getColonField<T>(val: val, field: string): T;
  getColonFieldLoc<T>(val: val, field: string, loc: SrcLocJs): T;
  getTuple<T>(tup: val, index: number, loc: SrcLocJs): T;
  checkTupleBind(tup: val, index: number, loc: SrcLocJs): boolean;
  extendObj(loc: SrcLocJs, obj: val, extension: Record<string, val>): val;

  isBase(v: unknown): v is PyretObject;
  isNothing(v: unknown): v is PyretNothing;
  isNumber(v: unknown): v is val;
  isRoughnum(v: unknown): v is PyretRoughNum;
  isExactnum(v: unknown): v is val;
  isString(v: unknown): v is PyretString;
  isBoolean(v: unknown): v is PyretBoolean;
  isFunction(v: unknown): v is func;
  isMethod(v: unknown): v is func;
  isTuple(v: unknown): v is PyretTuple;
  isObject(v: unknown): v is val;
  isDataValue(v: unknown): v is val;
  isRef(v: unknown): v is val;
  isOpaque(v: unknown): v is PyretOpaque;
  isPyretVal(v: unknown): v is val;

  isSuccessResult(v: unknown): v is ABI.SuccessResult;
  makeSuccessResult(r: unknown): ABI.SuccessResult;
  isFailureResult(v: unknown): v is ABI.FailureResult;
  makeFailureResult(e: unknown): ABI.FailureResult;

  makeNothing(): PyretNothing;
  makeNumber(n: number): val;
  makeNumberBig(n: unknown): val;
  makeNumberFromString(s: string): val;
  makeBoolean(b: boolean): PyretBoolean;
  makeString(s: string): PyretString;
  makeFunction(fun: func, name: string): PyretFunction;
  makeMethod(meth: func, full_meth: func, name: string): PyretMethod;
  // ...
  makeTuple(tup: val[]): PyretTuple;
  makeObject(obj: Record<string, val>): PyretObject;
  makeArray(arr: val[]): val;
  makeArrayN(n: number): val;

  // TODO:
  checkArrayIndex: func;
  makeBrandedObject: func;
  makeGraphableRef: func;
  makeRef: func;
  makeUnsafeSetRef: func;
  makeVariantConstructor: func;
  makeDataValue: func;
  makeDataTypeConstructor: func;
  makeMatch: func;
  makeOpqaue(val: any): PyretOpaque;

  // ...

  wrap(v: any): val;
  unwrap<T>(v: val): T;

  checkArity: (
    expected: number,
    args: IArguments,
    source: string,
    isMethod: boolean,
  ) => void;
  checkString(v: string): void;
  checkNumber(v: number): void;
  checkExactnum(v: number): void;
  checkRoughnum(v: number): void;
  checkNumInteger(v: number): void;
  checkNumRational(v: number): void;
  checkNumNegative(v: number): void;
  checkNumPositive(v: number): void;
  checkNumNonPositive(v: number): void;
  checkNumNonNegative(v: number): void;
  checkTuple(v: val): void;
  checkArray(v: val): void;
  checkBoolean(v: boolean): void;
  checkObject(v: val): void;
  checkFunction(v: val): void;
  checkMethod(v: val): void;
  checkOpaque(v: val): void;
  checkPyretVal(v: unknown): void;

  nothing: val;
  toRepr(v: val): val;

  makeSrcloc(srcloc: SrcLocJs): val;

  makeJSModuleReturn: (jsMod: any) => ret;
  makeModuleReturn: (
    values: Record<string, val>,
    types: Record<string, typ>,
    internal?: Record<string, unknown>,
  ) => ret;

  modules: Record<string, val>;

  stdout: typeof process.stdout;
  stderr: typeof process.stderr;
  stdin: typeof process.stdin;
  console: typeof console;

  makePrimAnn: unknown;
}

type PrimType =
  | "Number"
  | "String"
  | "Boolean"
  | "Nothing"
  | "Any"
  | "tany"
  | "tbot";
type TypeId = ["tid", string];
type Arrow = ["arrow", InteropSignature[], InteropSignature];
type ForAll = ["forall", string[], InteropSignature];
type ListOf = ["List", InteropSignature];
type ArrayOf = ["Array", InteropSignature];
type RawArrayOf = ["RawArray", InteropSignature];
type OptionOf = ["Option", InteropSignature];
type Maker = ["Maker", InteropSignature];
type InteropSignature =
  | ForAll
  | Arrow
  | TypeId
  | PrimType
  | ListOf
  | ArrayOf
  | RawArrayOf
  | OptionOf
  | Maker;

type RequireSpec =
  | { "import-type": "builtin"; name: string }
  | { "import-type": "dependency"; protocol: string; args: any[] };
interface PyretModule {
  requires: RequireSpec[];
  nativeRequires: any[];
  provides: {
    values?: Record<string, InteropSignature>;
    types?: Record<string, typ>;
  };
  theModule: (
    runtime: PyretRuntime,
    namespace: string,
    uri: string,
    ...imports: any[]
  ) => ret;
}
