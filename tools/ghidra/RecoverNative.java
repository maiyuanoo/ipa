import java.io.File;
import java.io.PrintWriter;
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

public class RecoverNative extends GhidraScript {
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
        Set<String> evidenceStrings = new HashSet<String>();
        evidenceStrings.add("FindPathLineCtrl");
        evidenceStrings.add("lineRender");
        evidenceStrings.add("pointsList");
        evidenceStrings.add("DrawPathPointLine");
        evidenceStrings.add("InitLoadLine");
        evidenceStrings.add("CameraFollow");
        evidenceStrings.add("UGC2FOV");
        evidenceStrings.add("UGC2FirstFOV");
        evidenceStrings.add("UGCObjectCoffin");
        evidenceStrings.add("DCODHFKCBGO");
        evidenceStrings.add("DGFGHBCDENH");
        evidenceStrings.add("IDBNHPMAGCN");
        evidenceStrings.add("set_fog");
        evidenceStrings.add("set_fogDensity");

        Set<Long> offsets = new HashSet<Long>();
        DataIterator dataIterator = currentProgram.getListing().getDefinedData(true);
        while (dataIterator.hasNext() && !monitor.isCancelled()) {
            Data data = dataIterator.next();
            Object value = data.getValue();
            if (!(value instanceof String) || !evidenceStrings.contains((String)value)) continue;

            ReferenceIterator references = currentProgram.getReferenceManager().getReferencesTo(data.getAddress());
            while (references.hasNext()) {
                Reference reference = references.next();
                Function function = currentProgram.getFunctionManager().getFunctionContaining(reference.getFromAddress());
                if (function == null) continue;
                offsets.add(function.getEntryPoint().getOffset());

                ReferenceIterator callers = currentProgram.getReferenceManager().getReferencesTo(function.getEntryPoint());
                while (callers.hasNext()) {
                    Function caller = currentProgram.getFunctionManager().getFunctionContaining(callers.next().getFromAddress());
                    if (caller != null) offsets.add(caller.getEntryPoint().getOffset());
                }
            }
        }
        return offsets;
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
