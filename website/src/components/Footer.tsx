import { APP_VERSION, GITHUB_URL } from "@/lib/constants";

export default function Footer() {
  return (
    <footer className="border-t border-gray-200 py-8 px-4">
      <div className="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-gray-500">
        <p>
          WinKeys v{APP_VERSION} &copy; {new Date().getFullYear()}
        </p>
        <div className="flex gap-4">
          <a
            href={GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-[#0078D4] transition-colors"
          >
            GitHub
          </a>
          <a href="#feedback" className="hover:text-[#0078D4] transition-colors">
            Feedback
          </a>
        </div>
      </div>
    </footer>
  );
}
