import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";

const feedbackDir = path.join(process.cwd(), "feedback");
const filePath = path.join(feedbackDir, "feedback.jsonl");

export async function GET() {
  try {
    await fs.mkdir(feedbackDir, { recursive: true });
    const raw = await fs.readFile(filePath, "utf-8").catch(() => "");
    const entries = raw
      .trim()
      .split("\n")
      .filter(Boolean)
      .map((line) => JSON.parse(line))
      .reverse(); // newest first

    return NextResponse.json(entries);
  } catch {
    return NextResponse.json([]);
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { name, category, appName, shortcut, message } = body;

    if (!name || !category || !message) {
      return NextResponse.json(
        { error: "Name, category, and message are required" },
        { status: 400 }
      );
    }

    const entry = {
      id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
      timestamp: new Date().toISOString(),
      name,
      category,
      ...(appName ? { appName } : {}),
      ...(shortcut ? { shortcut } : {}),
      message,
    };

    await fs.mkdir(feedbackDir, { recursive: true });
    await fs.appendFile(filePath, JSON.stringify(entry) + "\n");

    return NextResponse.json(entry, { status: 201 });
  } catch {
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
