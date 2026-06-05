import { spawn } from "node:child_process";
import * as fs from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";
import { BorderedLoader, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";

const VIEW_LAST_AI_COMMAND = "view-ai-md";
const SEND_MD_COMMAND = "send-md";
const DEFAULT_SHORTCUT = process.env.PI_VIEW_AI_MD_SHORTCUT || "alt+m";

function nowStamp(): string {
	return new Date().toISOString().replace(/[:.]/g, "-");
}

function stripOptionalAtPrefix(input: string): string {
	return input.startsWith("@") ? input.slice(1) : input;
}

function unquote(input: string): string {
	const trimmed = input.trim();
	if (
		(trimmed.startsWith('"') && trimmed.endsWith('"')) ||
		(trimmed.startsWith("'") && trimmed.endsWith("'"))
	) {
		return trimmed.slice(1, -1);
	}
	return trimmed;
}

function resolveUserPath(rawPath: string, cwd: string): string {
	let value = stripOptionalAtPrefix(unquote(rawPath));
	if (value === "~") return os.homedir();
	if (value.startsWith("~/") || value.startsWith("~\\")) {
		value = path.join(os.homedir(), value.slice(2));
	}
	return path.isAbsolute(value) ? value : path.resolve(cwd, value);
}

function parseFirstArg(args: string): { first?: string; rest: string } {
	const trimmed = args.trim();
	if (!trimmed) return { rest: "" };

	const quote = trimmed[0];
	if (quote === '"' || quote === "'") {
		let escaped = false;
		for (let i = 1; i < trimmed.length; i++) {
			const ch = trimmed[i];
			if (escaped) {
				escaped = false;
				continue;
			}
			if (ch === "\\") {
				escaped = true;
				continue;
			}
			if (ch === quote) {
				return { first: trimmed.slice(1, i), rest: trimmed.slice(i + 1).trim() };
			}
		}
	}

	const match = trimmed.match(/^(\S+)(?:\s+([\s\S]*))?$/);
	return { first: match?.[1], rest: match?.[2]?.trim() ?? "" };
}

function parseCount(args: string): number | undefined {
	const trimmed = args.trim();
	if (!trimmed) return 1;

	const direct = trimmed.match(/^\d+$/);
	if (direct) return Math.max(1, Number(direct[0]));

	const option = trimmed.match(/^(?:--count|-n)\s+(\d+)$/);
	if (option) return Math.max(1, Number(option[1]));

	return undefined;
}

function textFromContentPart(part: any): string | undefined {
	if (!part || typeof part !== "object") return undefined;
	if (typeof part.text === "string") return part.text;
	if (part.type === "thinking" && typeof part.thinking === "string") {
		return `> [thinking]\n${part.thinking}`;
	}
	return undefined;
}

function messageText(message: any): string {
	const content = message?.content;
	if (typeof content === "string") return content.trim();
	if (Array.isArray(content)) {
		const text = content
			.map(textFromContentPart)
			.filter((part): part is string => Boolean(part && part.trim()))
			.join("\n\n")
			.trim();
		if (text) return text;
	}
	return "";
}

function getAssistantTextMessages(ctx: ExtensionContext): Array<{ entryId?: string; timestamp?: number; text: string }> {
	return ctx.sessionManager
		.getBranch()
		.filter((entry: any) => entry?.type === "message" && entry.message?.role === "assistant")
		.map((entry: any) => ({
			entryId: entry.id,
			timestamp: entry.message?.timestamp ?? entry.timestamp,
			text: messageText(entry.message),
		}))
		.filter((item) => item.text.length > 0);
}

function formatAssistantMessagesMarkdown(
	messages: Array<{ entryId?: string; timestamp?: number; text: string }>,
	ctx: ExtensionContext,
): string {
	const header = [
		"# Pi assistant message export",
		"",
		`- Exported: ${new Date().toISOString()}`,
		`- Session: ${ctx.sessionManager.getSessionFile() ?? "ephemeral"}`,
		`- Count: ${messages.length}`,
		"",
		"---",
		"",
	];

	const body = messages.flatMap((message, index) => {
		const lines = [
			`## Assistant message ${index + 1}`,
			"",
			...(message.timestamp ? [`- Time: ${new Date(message.timestamp).toISOString()}`] : []),
			...(message.entryId ? [`- Entry: ${message.entryId}`] : []),
			"",
			message.text,
		];
		if (index < messages.length - 1) lines.push("", "---", "");
		return lines;
	});

	return [...header, ...body, ""].join("\n");
}

async function writeAssistantMessagesToTemp(ctx: ExtensionContext, count: number): Promise<string | undefined> {
	const assistantMessages = getAssistantTextMessages(ctx);
	const selected = assistantMessages.slice(-count);
	if (selected.length === 0) {
		ctx.ui.notify("No assistant text messages found in the current branch", "warning");
		return undefined;
	}

	const tempFile = path.join(os.tmpdir(), `pi-assistant-messages-${nowStamp()}.md`);
	await fs.writeFile(tempFile, formatAssistantMessagesMarkdown(selected, ctx), "utf-8");
	return tempFile;
}

async function spawnEditor(editorCmd: string, filePath: string): Promise<number | null> {
	const [editor, ...editorArgs] = editorCmd.split(" ").filter(Boolean);
	if (!editor) return null;

	return new Promise<number | null>((resolve) => {
		const child = spawn(editor, [...editorArgs, filePath], {
			stdio: "inherit",
			shell: process.platform === "win32",
		});
		child.on("error", () => resolve(null));
		child.on("close", (code) => resolve(code));
	});
}

async function openExternalEditor(ctx: ExtensionContext, filePath: string): Promise<number | null | undefined> {
	const editorCmd = process.env.VISUAL || process.env.EDITOR;
	if (!editorCmd) {
		ctx.ui.notify("Set VISUAL or EDITOR before using view-ai-md", "error");
		return undefined;
	}

	if (!ctx.hasUI) {
		return spawnEditor(editorCmd, filePath);
	}

	return ctx.ui.custom<number | null>((tui, theme, _keybindings, done) => {
		const loader = new BorderedLoader(tui, theme, `Opening ${path.basename(filePath)} with ${editorCmd}...`);

		queueMicrotask(async () => {
			let status: number | null = null;
			try {
				tui.stop();
				process.stdout.write(`Launching external editor: ${editorCmd}\nFile: ${filePath}\nPi will resume when the editor exits.\n`);
				status = await spawnEditor(editorCmd, filePath);
			} finally {
				tui.start();
				tui.requestRender(true);
				done(status);
			}
		});

		return loader;
	});
}

async function viewLastAssistantMessages(ctx: ExtensionContext, rawArgs = ""): Promise<void> {
	const count = parseCount(rawArgs);
	if (count === undefined) {
		ctx.ui.notify(`Usage: /${VIEW_LAST_AI_COMMAND} [count]`, "warning");
		return;
	}

	if (!ctx.isIdle()) {
		ctx.ui.notify("Agent is busy. Run this again after the current response finishes.", "warning");
		return;
	}

	try {
		const tempFile = await writeAssistantMessagesToTemp(ctx, count);
		if (!tempFile) return;

		const status = await openExternalEditor(ctx, tempFile);
		if (status === 0) {
			ctx.ui.notify(`Assistant markdown opened: ${tempFile}`, "info");
		} else if (status === undefined) {
			ctx.ui.notify(`Assistant markdown saved: ${tempFile}`, "info");
		} else {
			ctx.ui.notify(`Editor exited with status ${status ?? "unknown"}. File kept: ${tempFile}`, "warning");
		}
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		ctx.ui.notify(`Failed to export assistant messages: ${message}`, "error");
	}
}

export default function assistantMdBridge(pi: ExtensionAPI) {
	pi.registerCommand(VIEW_LAST_AI_COMMAND, {
		description: "Export the last assistant message(s) to a temp markdown file and open $VISUAL/$EDITOR",
		handler: async (args, ctx) => {
			await viewLastAssistantMessages(ctx, args);
		},
	});

	pi.registerShortcut(DEFAULT_SHORTCUT as any, {
		description: `Export last assistant message to temp markdown and open external editor (/${VIEW_LAST_AI_COMMAND})`,
		handler: async (ctx) => {
			await viewLastAssistantMessages(ctx);
		},
	});

	pi.registerCommand(SEND_MD_COMMAND, {
		description: "Load a local markdown file and send its contents as a user message",
		handler: async (args, ctx) => {
			let target = parseFirstArg(args).first;
			if (!target) {
				target = await ctx.ui.input("Markdown file path", "./prompt.md");
			}
			if (!target) return;

			try {
				const filePath = resolveUserPath(target, ctx.cwd);
				const markdown = await fs.readFile(filePath, "utf-8");
				if (!markdown.trim()) {
					ctx.ui.notify(`Markdown file is empty: ${filePath}`, "warning");
					return;
				}

				if (ctx.isIdle()) {
					pi.sendUserMessage(markdown);
				} else {
					pi.sendUserMessage(markdown, { deliverAs: "followUp" });
					ctx.ui.notify("Agent is busy. Markdown user message queued as follow-up.", "info");
				}
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`Failed to send markdown file: ${message}`, "error");
			}
		},
	});
}
