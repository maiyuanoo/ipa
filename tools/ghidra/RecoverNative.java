import java.io.File;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.DataIterator;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import ghidra.program.model.address.Address;

public class RecoverNative extends GhidraScript {
    private static final int MAX_EVIDENCE_FUNCTIONS = 96;
    private static final int MAX_DIRECT_CALLEES_PER_EVIDENCE_FUNCTION = 20;

    private boolean isTargetFunction(String functionName) {
        return functionName.contains("YYGameMemory") ||
            functionName.contains("YYUnity") ||
            functionName.contains("YYIslandRoute") ||
            functionName.contains("hookui_") ||
            functionName.startsWith("_B3m::") ||
            functionName.startsWith("_E5w::") ||
            functionName.equals("RussIslandRouteOverlaySetEnabled") ||
            functionName.equals("RussIslandRouteOverlayShutdown");
    }

    private boolean isRuntimeDispatcher(Function function) {
        long entryOffset = function.getEntryPoint().getOffset();
        return entryOffset == 0x0a474L || entryOffset == 0x0a528L ||
            entryOffset == 0x0a538L || entryOffset == 0x0a5d4L ||
            entryOffset == 0x0a6dcL || entryOffset == 0x0a75cL ||
            entryOffset == 0x0a864L || entryOffset == 0x2537f8L ||
            entryOffset == 0x2537fcL ||
            entryOffset == 0x17098L || entryOffset == 0x17184L ||
            entryOffset == 0x0684cL || entryOffset == 0x06bf4L ||
            entryOffset == 0x06c64L || entryOffset == 0x06d1cL ||
            entryOffset == 0x07d20L || entryOffset == 0x07ef8L ||
            entryOffset == 0x08184L || entryOffset == 0x08294L ||
            entryOffset == 0x08308L || entryOffset == 0x08404L ||
            entryOffset == 0x07cc0L ||
            entryOffset == 0x07f64L || entryOffset == 0x080a0L ||
            entryOffset == 0x08108L || entryOffset == 0x08614L ||
            entryOffset == 0x088f8L || entryOffset == 0x08b64L ||
            entryOffset == 0x08c20L || entryOffset == 0x08c68L ||
            entryOffset == 0x08d1cL || entryOffset == 0x09394L ||
            entryOffset == 0x09418L || entryOffset == 0x094ccL ||
            entryOffset == 0x09570L || entryOffset == 0x09690L ||
            entryOffset == 0x09708L ||
            // 辞月实体缓存快照：读取、写入和释放辅助函数。
            entryOffset == 0x03e7e8L || entryOffset == 0x066584L ||
            entryOffset == 0x0723c4L || entryOffset == 0x074720L ||
            entryOffset == 0x0861acL || entryOffset == 0x086210L ||
            entryOffset == 0x08634cL || entryOffset == 0x0863ecL ||
            entryOffset == 0x0868bcL || entryOffset == 0x086934L ||
            entryOffset == 0x086eb4L || entryOffset == 0x086fa4L ||
            entryOffset == 0x08701cL ||
            entryOffset == 0x17720L || entryOffset == 0x195a8L ||
            entryOffset == 0x19624L || entryOffset == 0x19894L ||
            entryOffset == 0x19afcL || entryOffset == 0x19cf0L ||
            entryOffset == 0x19de8L ||
            entryOffset == 0x1a0f4L || entryOffset == 0x1a2d8L ||
            entryOffset == 0x1a3b0L ||
            entryOffset == 0x1a330L ||
            entryOffset == 0x1a400L || entryOffset == 0x1a480L ||
            entryOffset == 0x1a4e8L || entryOffset == 0x1a540L ||
            entryOffset == 0x1a5b0L || entryOffset == 0x1a730L ||
            entryOffset == 0x1a7b8L || entryOffset == 0x1aaa4L ||
            entryOffset == 0x1ab08L || entryOffset == 0x1abecL ||
            entryOffset == 0x1ac8cL || entryOffset == 0x1ad7cL ||
            entryOffset == 0x1ae10L || entryOffset == 0x1af00L ||
            entryOffset == 0x1af60L || entryOffset == 0x1b070L ||
            entryOffset == 0x1b47cL || entryOffset == 0x1b500L ||
            entryOffset == 0x1b628L || entryOffset == 0x1b664L ||
            entryOffset == 0x1b7bcL || entryOffset == 0x1b968L ||
            entryOffset == 0x1ba54L || entryOffset == 0x1bb90L ||
            entryOffset == 0x1bce4L || entryOffset == 0x1bd94L ||
            entryOffset == 0x1be30L || entryOffset == 0x1bedcL ||
            entryOffset == 0x1bef0L || entryOffset == 0x3ee08L ||
            entryOffset == 0x3ee20L;
    }

    private Set<Long> getBlockInvokeOffsets() throws Exception {
        long[] blockOffsets = {
            0xe11f0L, 0xe1210L, 0xe1230L, 0xe1250L, 0xe1270L,
            0xe1290L, 0xe12b0L, 0xe12d0L, 0xe12f0L, 0xe1310L,
            0xe1330L
        };
        Memory memory = currentProgram.getMemory();
        Set<Long> invokeOffsets = new HashSet<Long>();

        for (long blockOffset : blockOffsets) {
            long invokeAddress = memory.getLong(toAddr(blockOffset + 0x10L));
            if (invokeAddress != 0) {
                invokeOffsets.add(invokeAddress & 0xffffffffL);
            }
        }
        return invokeOffsets;
    }

    private Set<Long> getEvidenceReferenceOffsets() {
        Set<String> evidenceStrings = getEvidenceStrings();
        Set<Long> offsets = new HashSet<Long>();

        // Mach-O 的 __cstring 经常未被 Ghidra 定义为 Data，因此先直接扫描字节。
        for (String evidence : evidenceStrings) {
            addEvidenceReferences(evidence, offsets);
            if (offsets.size() >= MAX_EVIDENCE_FUNCTIONS) return offsets;
        }

        // 保留已定义 Data 的处理，用于 Russ 样本中已正确导入的字符串。
        DataIterator dataIterator = currentProgram.getListing().getDefinedData(true);
        while (dataIterator.hasNext() && !monitor.isCancelled()) {
            Data data = dataIterator.next();
            Object value = data.getValue();
            if (!(value instanceof String) || !evidenceStrings.contains((String)value)) continue;
            addFunctionAndCallerReferences(data.getAddress(), offsets, true);
            if (offsets.size() >= MAX_EVIDENCE_FUNCTIONS) return offsets;
        }
        return offsets;
    }

    private void addEvidenceReferences(String evidence, Set<Long> offsets) {
        Memory memory = currentProgram.getMemory();
        byte[] bytes = evidence.getBytes(StandardCharsets.UTF_8);
        Address searchStart = currentProgram.getMinAddress();
        while (searchStart != null && !monitor.isCancelled() && offsets.size() < MAX_EVIDENCE_FUNCTIONS) {
            Address match;
            try {
                match = memory.findBytes(searchStart, bytes, null, true, monitor);
            } catch (Exception exception) {
                return;
            }
            if (match == null) return;
            addFunctionAndCallerReferences(match, offsets, false);
            try {
                searchStart = match.add(1);
            } catch (Exception exception) {
                return;
            }
        }
    }

    private void addFunctionAndCallerReferences(Address address, Set<Long> offsets, boolean followDataReferences) {
        ReferenceIterator references = currentProgram.getReferenceManager().getReferencesTo(address);
        while (references.hasNext() && offsets.size() < MAX_EVIDENCE_FUNCTIONS) {
            Reference reference = references.next();
            Function function = currentProgram.getFunctionManager().getFunctionContaining(reference.getFromAddress());
            if (function != null) {
                offsets.add(function.getEntryPoint().getOffset());
                addCallers(function, offsets);
                addDirectCallees(function, offsets);
            } else if (!followDataReferences) {
                // Objective-C 常量字符串先由 __cfstring 数据项引用，再由代码引用该数据项。
                addFunctionAndCallerReferences(reference.getFromAddress(), offsets, true);
            }
        }
    }

    private void addCallers(Function function, Set<Long> offsets) {
        ReferenceIterator callers = currentProgram.getReferenceManager().getReferencesTo(function.getEntryPoint());
        while (callers.hasNext() && offsets.size() < MAX_EVIDENCE_FUNCTIONS) {
            Function caller = currentProgram.getFunctionManager().getFunctionContaining(callers.next().getFromAddress());
            if (caller != null) offsets.add(caller.getEntryPoint().getOffset());
        }
    }

    private void addDirectCallees(Function function, Set<Long> offsets) {
        int added = 0;
        try {
            for (Function callee : function.getCalledFunctions(monitor)) {
                if (callee == null || offsets.size() >= MAX_EVIDENCE_FUNCTIONS ||
                    added >= MAX_DIRECT_CALLEES_PER_EVIDENCE_FUNCTION) {
                    return;
                }
                if (offsets.add(callee.getEntryPoint().getOffset())) added++;
            }
        } catch (Exception exception) {
            // 某些间接调用无法在静态分析中解析，保留已有字符串引用结果。
        }
    }

    private Set<String> getEvidenceStrings() {
        Set<String> evidenceStrings = new HashSet<String>();
        String[] values = {
            "FindPathLineCtrl", "lineRender", "pointsList", "DrawPathPointLine", "InitLoadLine",
            "CameraFollow", "UGC2FOV", "UGC2FirstFOV", "UGCObjectCoffin", "DCODHFKCBGO",
            "DGFGHBCDENH", "IDBNHPMAGCN", "set_fog", "set_fogDensity",
            // 辞月样本中与 Metal 绘制文本直接相邻的实体类别和物资标签。
            "Monster", "Enemy", "Chest", "Item", "Loot", "Unknown Item", "PlayerA.png", "物资"
        };
        for (String value : values) evidenceStrings.add(value);
        return evidenceStrings;
    }

    private void writePointerChain(PrintWriter writer, long address, int count) {
        writer.printf("/* Pointer chain at 0x%08x:", address);
        try {
            for (int index = 0; index < count; index++) {
                long value = currentProgram.getMemory().getLong(toAddr(address + index * 8L));
                writer.printf(" 0x%016x", value);
            }
        } catch (Exception exception) {
            writer.printf(" unavailable: %s", exception.getMessage());
        }
        writer.println(" */");
    }

    @Override
    public void run() throws Exception {
        String[] arguments = getScriptArgs();
        if (arguments.length != 1) {
            throw new IllegalArgumentException("Expected output file path");
        }

        File outputFile = new File(arguments[0]);
        File parentDirectory = outputFile.getParentFile();
        if (parentDirectory != null && !parentDirectory.exists() && !parentDirectory.mkdirs()) {
            throw new IllegalStateException("Unable to create output directory");
        }

        DecompInterface decompiler = new DecompInterface();
        decompiler.setSimplificationStyle("decompile");
        if (!decompiler.openProgram(currentProgram)) {
            throw new IllegalStateException("Unable to open program for decompilation");
        }

        int recoveredCount = 0;
        List<Function> allFunctions = new ArrayList<Function>();
        List<Function> targetFunctions = new ArrayList<Function>();
        Set<Long> blockInvokeOffsets = getBlockInvokeOffsets();
        Set<Long> evidenceReferenceOffsets = getEvidenceReferenceOffsets();
        FunctionIterator functions = currentProgram.getFunctionManager().getFunctions(true);
        while (functions.hasNext() && !monitor.isCancelled()) {
            Function function = functions.next();
            allFunctions.add(function);
            if (isTargetFunction(function.getName()) || isRuntimeDispatcher(function) ||
                blockInvokeOffsets.contains(function.getEntryPoint().getOffset()) ||
                evidenceReferenceOffsets.contains(function.getEntryPoint().getOffset())) {
                targetFunctions.add(function);
            }
        }

        try (PrintWriter writer = new PrintWriter(outputFile, "UTF-8")) {
            writer.printf("/* Generated by Ghidra from %s. */%n", currentProgram.getName());
            writer.printf("/* Evidence strings: %s */%n", getEvidenceStrings());
            writer.printf("/* Evidence-selected function offsets: %s */%n", evidenceReferenceOffsets);
            if (currentProgram.getName().contains("RussOriginal")) {
                writePointerChain(writer, 0x000d71a0L, 8);
                writePointerChain(writer, 0x000d71e0L, 5);
                writePointerChain(writer, 0x000d7180L, 5);
                writePointerChain(writer, 0x000d7160L, 3);
            }
            for (Function function : targetFunctions) {
                String functionName = function.getName();
                DecompileResults result = decompiler.decompileFunction(function, 120, monitor);
                if (!result.decompileCompleted() || result.getDecompiledFunction() == null) {
                    writer.printf("/* Unable to decompile %s at %s */%n%n", functionName, function.getEntryPoint());
                    continue;
                }

                writer.printf("/* %s at %s */%n", functionName, function.getEntryPoint());
                writer.println(result.getDecompiledFunction().getC());
                writer.println();
                recoveredCount++;
            }
            writer.printf("/* Recovered functions: %d */%n", recoveredCount);
            if (recoveredCount == 0) {
                writer.println("/* Target symbols were not retained by the importer. */");
                writer.println("/* Function inventory for the next recovery pass: */");
                for (Function function : allFunctions) {
                    writer.printf("/* %s at %s */%n", function.getName(), function.getEntryPoint());
                }
            }
        } finally {
            decompiler.dispose();
        }
    }
}
