using System.Reflection;
using System.Reflection.Emit;
using System.Reflection.Metadata;
using System.Reflection.Metadata.Ecma335;
using System.Reflection.PortableExecutable;

if (args.Length != 1)
{
    Console.Error.WriteLine("用法: EntityCollectionIlAnalysis <UpdateScript_500.dll>");
    return 2;
}

using var stream = File.OpenRead(Path.GetFullPath(args[0]));
using var peReader = new PEReader(stream);
var metadata = peReader.GetMetadataReader();
var targetType = metadata.TypeDefinitions
    .Select(handle => (Handle: handle, Definition: metadata.GetTypeDefinition(handle)))
    .FirstOrDefault(item => metadata.GetString(item.Definition.Name) == "OEPJBOIGGPO");

if (targetType.Handle.IsNil)
{
    Console.Error.WriteLine("未找到 OEPJBOIGGPO。");
    return 3;
}

var trackedFields = targetType.Definition.GetFields()
    .Select(handle => (Token: MetadataTokens.GetToken(handle), Name: metadata.GetString(metadata.GetFieldDefinition(handle).Name)))
    .Where(field => field.Name is "NLMAFONOFFH" or "CMPKHKEGCKK" or "IMDDIDNCIPO")
    .ToDictionary(field => field.Token, field => field.Name);

var snapshotMethod = targetType.Definition.GetMethods()
    .Select(handle => (Handle: handle, Definition: metadata.GetMethodDefinition(handle)))
    .FirstOrDefault(item => metadata.GetString(item.Definition.Name) == "JHDAFFFAKCK");

if (snapshotMethod.Handle.IsNil || snapshotMethod.Definition.RelativeVirtualAddress == 0 ||
    !HasNoParameters(snapshotMethod.Definition, metadata))
{
    Console.Error.WriteLine("未找到零参数实体快照方法 JHDAFFFAKCK。");
    return 4;
}

var snapshotInstructions = ReadInstructions(
    peReader.GetMethodBody(snapshotMethod.Definition.RelativeVirtualAddress).GetILBytes() ?? []).ToArray();
var snapshotMemberNames = snapshotInstructions
    .Where(instruction => instruction.Operand is int token && IsMetadataToken(token))
    .Select(instruction => ResolveToken(metadata, (int)instruction.Operand!))
    .ToHashSet(StringComparer.Ordinal);
var hasEntityCollectionField = snapshotInstructions.Any(instruction =>
    instruction.OpCode == OpCodes.Ldfld && instruction.Operand is int token &&
    trackedFields.TryGetValue(token, out var fieldName) && fieldName == "NLMAFONOFFH");
var requiredSnapshotMembers = new[] { "member get_Values", "member GetEnumerator", "member get_Current", "member Add" };
var missingSnapshotMembers = requiredSnapshotMembers
    .Where(member => !snapshotMemberNames.Contains(member))
    .ToArray();

if (!hasEntityCollectionField || !snapshotInstructions.Any(instruction => instruction.OpCode == OpCodes.Newobj) ||
    missingSnapshotMembers.Length > 0)
{
    Console.Error.WriteLine("JHDAFFFAKCK 不符合 NLMAFONOFFH.Values 实体快照契约。");
    if (!hasEntityCollectionField) Console.Error.WriteLine("缺少字段读取: NLMAFONOFFH。");
    if (!snapshotInstructions.Any(instruction => instruction.OpCode == OpCodes.Newobj)) Console.Error.WriteLine("缺少列表构造。");
    if (missingSnapshotMembers.Length > 0) Console.Error.WriteLine("缺少成员调用: " + string.Join(", ", missingSnapshotMembers));
    return 5;
}

var managerInstanceField = targetType.Definition.GetFields()
    .Select(handle => metadata.GetFieldDefinition(handle))
    .FirstOrDefault(field => metadata.GetString(field.Name) == "BHOAGIJIMMJ");
var entityType = metadata.TypeDefinitions
    .Select(handle => (Handle: handle, Definition: metadata.GetTypeDefinition(handle)))
    .FirstOrDefault(item => metadata.GetString(item.Definition.Name) == "DIGLCECMPAB");

if (managerInstanceField.Name.IsNil || !managerInstanceField.Attributes.HasFlag(FieldAttributes.Static) || entityType.Handle.IsNil)
{
    Console.Error.WriteLine("未找到实体绘制所需的静态管理器字段或实体类型。");
    return 6;
}

var entityFieldNames = entityType.Definition.GetFields()
    .Select(handle => metadata.GetString(metadata.GetFieldDefinition(handle).Name))
    .ToHashSet(StringComparer.Ordinal);
var entityTransformMethod = entityType.Definition.GetMethods()
    .Select(handle => (Handle: handle, Definition: metadata.GetMethodDefinition(handle)))
    .FirstOrDefault(item => metadata.GetString(item.Definition.Name) == "MCCJPBBPEMK");
var requiredEntityFields = new[] { "<EPOOFKEKHEN>k__BackingField", "LCBPLHGAECL", "OOKGDEJMAKP" };
var missingEntityFields = requiredEntityFields.Where(field => !entityFieldNames.Contains(field)).ToArray();

if (entityTransformMethod.Handle.IsNil || !HasNoParameters(entityTransformMethod.Definition, metadata) ||
    missingEntityFields.Length > 0)
{
    Console.Error.WriteLine("DIGLCECMPAB 不符合已确认的 Transform 或名称读取契约。");
    if (entityTransformMethod.Handle.IsNil || !HasNoParameters(entityTransformMethod.Definition, metadata)) {
        Console.Error.WriteLine("缺少零参数 Transform 方法: MCCJPBBPEMK。");
    }
    if (missingEntityFields.Length > 0) Console.Error.WriteLine("缺少实体字段: " + string.Join(", ", missingEntityFields));
    return 7;
}

Console.WriteLine("# OEPJBOIGGPO 实体集合 IL 审计");
Console.WriteLine();
Console.WriteLine("输入程序集: UpdateScript_500.dll");
Console.WriteLine("审计字段: " + string.Join(", ", trackedFields.Values));
Console.WriteLine("快照契约: JHDAFFFAKCK 从 NLMAFONOFFH.Values 构造实体列表（已验证）");
Console.WriteLine("绘制读取契约: BHOAGIJIMMJ、DIGLCECMPAB、MCCJPBBPEMK 和名称字段（已验证）");

foreach (var methodHandle in targetType.Definition.GetMethods())
{
    var method = metadata.GetMethodDefinition(methodHandle);
    if (method.RelativeVirtualAddress == 0)
    {
        continue;
    }

    var il = peReader.GetMethodBody(method.RelativeVirtualAddress).GetILBytes();
    if (il is null || !ReferencesTrackedField(il, trackedFields))
    {
        continue;
    }

    Console.WriteLine();
    Console.WriteLine($"## {metadata.GetString(method.Name)} (0x{MetadataTokens.GetToken(methodHandle):X8})");
    foreach (var instruction in Decode(il, metadata, trackedFields))
    {
        Console.WriteLine(instruction);
    }
}

return 0;

static bool ReferencesTrackedField(byte[] il, IReadOnlyDictionary<int, string> trackedFields)
{
    foreach (var instruction in ReadInstructions(il))
    {
        if (instruction.Operand is int token && trackedFields.ContainsKey(token))
        {
            return true;
        }
    }
    return false;
}

static bool HasNoParameters(MethodDefinition method, MetadataReader metadata) =>
    !method.GetParameters().Any(handle => metadata.GetParameter(handle).SequenceNumber > 0);

static IEnumerable<string> Decode(byte[] il, MetadataReader metadata, IReadOnlyDictionary<int, string> trackedFields)
{
    foreach (var instruction in ReadInstructions(il))
    {
        var operand = instruction.Operand switch
        {
            int token when trackedFields.TryGetValue(token, out var fieldName) => $"{fieldName} [字段]",
            int token when IsMetadataToken(token) => ResolveToken(metadata, token),
            int value => $"0x{value:X}",
            byte value => value.ToString(),
            ushort value => value.ToString(),
            long value => value.ToString(),
            float value => value.ToString(System.Globalization.CultureInfo.InvariantCulture),
            double value => value.ToString(System.Globalization.CultureInfo.InvariantCulture),
            null => string.Empty,
            _ => instruction.Operand.ToString() ?? string.Empty
        };
        yield return $"IL_{instruction.Offset:X4}: {instruction.OpCode.Name}{(string.IsNullOrEmpty(operand) ? string.Empty : " " + operand)}";
    }
}

static bool IsMetadataToken(int token) => (uint)token >> 24 is >= 0x01 and <= 0x2B;

static string ResolveToken(MetadataReader metadata, int token)
{
    try
    {
        var handle = MetadataTokens.EntityHandle(token);
        return handle.Kind switch
        {
            HandleKind.FieldDefinition => "field " + metadata.GetString(metadata.GetFieldDefinition((FieldDefinitionHandle)handle).Name),
            HandleKind.MethodDefinition => "method " + metadata.GetString(metadata.GetMethodDefinition((MethodDefinitionHandle)handle).Name),
            HandleKind.MemberReference => "member " + metadata.GetString(metadata.GetMemberReference((MemberReferenceHandle)handle).Name),
            HandleKind.TypeDefinition => "type " + metadata.GetString(metadata.GetTypeDefinition((TypeDefinitionHandle)handle).Name),
            HandleKind.TypeReference => "type " + metadata.GetString(metadata.GetTypeReference((TypeReferenceHandle)handle).Name),
            _ => $"token 0x{token:X8}"
        };
    }
    catch (BadImageFormatException)
    {
        return $"token 0x{token:X8}";
    }
}

static IEnumerable<IlInstruction> ReadInstructions(byte[] il)
{
    var offset = 0;
    while (offset < il.Length)
    {
        var instructionOffset = offset;
        var opcodeValue = (int)il[offset++];
        if (opcodeValue == 0xFE && offset < il.Length)
        {
            opcodeValue = (short)(0xFE00 | il[offset++]);
        }
        if (!IlOpcodeMap.Value.TryGetValue((short)opcodeValue, out var opcode))
        {
            yield break;
        }

        var operand = ReadOperand(opcode.OperandType, il, ref offset);
        yield return new IlInstruction(instructionOffset, opcode, operand);
    }
}

static object? ReadOperand(OperandType operandType, byte[] il, ref int offset)
{
    return operandType switch
    {
        OperandType.InlineNone => null,
        OperandType.ShortInlineI => il[offset++],
        OperandType.ShortInlineVar => il[offset++],
        OperandType.InlineVar => ReadUInt16(il, ref offset),
        OperandType.InlineI or OperandType.InlineBrTarget or OperandType.InlineField or OperandType.InlineMethod or OperandType.InlineSig or OperandType.InlineString or OperandType.InlineTok or OperandType.InlineType => ReadInt32(il, ref offset),
        OperandType.InlineI8 => ReadInt64(il, ref offset),
        OperandType.ShortInlineR => ReadSingle(il, ref offset),
        OperandType.InlineR => ReadDouble(il, ref offset),
        OperandType.ShortInlineBrTarget => (sbyte)il[offset++],
        OperandType.InlineSwitch => ReadSwitch(il, ref offset),
        _ => null
    };
}

static int ReadInt32(byte[] data, ref int offset)
{
    var value = BitConverter.ToInt32(data, offset);
    offset += sizeof(int);
    return value;
}

static ushort ReadUInt16(byte[] data, ref int offset)
{
    var value = BitConverter.ToUInt16(data, offset);
    offset += sizeof(ushort);
    return value;
}

static long ReadInt64(byte[] data, ref int offset)
{
    var value = BitConverter.ToInt64(data, offset);
    offset += sizeof(long);
    return value;
}

static float ReadSingle(byte[] data, ref int offset)
{
    var value = BitConverter.ToSingle(data, offset);
    offset += sizeof(float);
    return value;
}

static double ReadDouble(byte[] data, ref int offset)
{
    var value = BitConverter.ToDouble(data, offset);
    offset += sizeof(double);
    return value;
}

static int[] ReadSwitch(byte[] data, ref int offset)
{
    var count = BitConverter.ToInt32(data, offset);
    offset += sizeof(int);
    var targets = new int[count];
    for (var index = 0; index < count; index++)
    {
        targets[index] = BitConverter.ToInt32(data, offset);
        offset += sizeof(int);
    }
    return targets;
}

internal readonly record struct IlInstruction(int Offset, OpCode OpCode, object? Operand);

internal static class IlOpcodeMap
{
    internal static readonly IReadOnlyDictionary<short, OpCode> Value = typeof(OpCodes)
        .GetFields(BindingFlags.Public | BindingFlags.Static)
        .Where(field => field.FieldType == typeof(OpCode))
        .Select(field => (OpCode)field.GetValue(null)!)
        .ToDictionary(opcode => opcode.Value);
}
