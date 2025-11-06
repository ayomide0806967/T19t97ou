import { useState, useRef } from "react";
import {
  MessageCircle,
  Repeat2,
  Heart,
  Share2,
  Paperclip,
  Image as ImageIcon,
  Smile,
  Send,
} from "lucide-react";

export default function TweetCard() {
  const [reply, setReply] = useState("");
  const textareaRef = useRef(null);

  const handleChange = (e) => {
    setReply(e.target.value);
    if (textareaRef.current) {
      textareaRef.current.style.height = "0px";
      const { scrollHeight } = textareaRef.current;
      textareaRef.current.style.height = Math.min(scrollHeight, 160) + "px";
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const text = reply.trim();
    if (!text) return;
    // Hook up to your submit logic here
    // e.g., onReply(text)
    setReply("");
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
    }
  };

  return (
    <div className="max-w-xl mx-auto bg-white/10 backdrop-blur-xl border border-white/20 rounded-3xl shadow-lg p-5 hover:bg-white/15 transition-all duration-300">
      {/* Profile section */}
      <div className="flex items-start space-x-3">
        <img
          src="https://i.pravatar.cc/100?img=32"
          alt="User avatar"
          className="w-12 h-12 rounded-full ring-2 ring-teal-500/40"
          loading="lazy"
          decoding="async"
        />
        <div className="flex-1">
          <div className="flex justify-between items-center">
            <div>
              <h3 className="font-semibold text-white text-lg">Dr. Zainab Musa</h3>
              <p className="text-sm text-gray-300">@zainabmusa</p>
            </div>
            <span className="text-gray-400 text-sm">2h</span>
          </div>

          {/* Tweet text */}
          <p className="mt-3 text-gray-100 text-[15px] leading-relaxed">
            Nursing education evolves fast. Academic Nightingale ensures you stay ahead — with new CBT mock patterns aligned to NMCN updates.
          </p>

          {/* Action bar */}
          <div className="flex justify-between items-center mt-4 text-gray-300 text-sm select-none">
            <button className="flex items-center space-x-1 hover:text-teal-400 transition">
              <MessageCircle className="w-5 h-5" />
              <span>25</span>
            </button>
            <button className="flex items-center space-x-1 hover:text-teal-500 transition">
              <Repeat2 className="w-5 h-5 text-teal-500" />
              <span className="font-semibold text-teal-400">RE-IN</span>
            </button>
            <button className="flex items-center space-x-1 hover:text-pink-500 transition">
              <Heart className="w-5 h-5" />
              <span>134</span>
            </button>
            <button className="flex items-center space-x-1 hover:text-sky-400 transition">
              <Share2 className="w-5 h-5" />
            </button>
          </div>

          {/* Reply (OpenAI-style) */}
          <form onSubmit={handleSubmit} className="mt-5">
            <p className="text-xs text-gray-400 mb-2">
              Replying to <span className="text-teal-400">@zainabmusa</span>
            </p>
            <div className="rounded-2xl border border-white/10 bg-white/[0.03] focus-within:border-white/20 transition-colors">
              <div className="flex items-start gap-3 p-3">
                <img
                  src="https://i.pravatar.cc/100?img=64"
                  alt="Your avatar"
                  className="w-9 h-9 rounded-full"
                  loading="lazy"
                  decoding="async"
                />
                <div className="flex-1">
                  <label htmlFor="reply" className="sr-only">
                    Write a reply
                  </label>
                  <textarea
                    id="reply"
                    ref={textareaRef}
                    rows={1}
                    value={reply}
                    onChange={handleChange}
                    placeholder="Write a reply..."
                    className="w-full bg-transparent text-gray-100 placeholder-gray-400 text-[15px] leading-relaxed outline-none resize-none max-h-40"
                  />
                  <div className="mt-2 flex items-center justify-between">
                    <div className="flex items-center gap-1.5 text-gray-400">
                      <button type="button" className="p-2 rounded-md hover:bg-white/5" aria-label="Attach file">
                        <Paperclip className="w-5 h-5" />
                      </button>
                      <button type="button" className="p-2 rounded-md hover:bg-white/5" aria-label="Insert image">
                        <ImageIcon className="w-5 h-5" />
                      </button>
                      <button type="button" className="p-2 rounded-md hover:bg-white/5" aria-label="Insert emoji">
                        <Smile className="w-5 h-5" />
                      </button>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-xs text-gray-400">{reply.length}/280</span>
                      <button
                        type="submit"
                        disabled={!reply.trim()}
                        className="inline-flex items-center justify-center w-9 h-9 rounded-full bg-emerald-500 text-white hover:bg-emerald-600 disabled:opacity-40 disabled:hover:bg-emerald-500 transition-colors"
                        aria-label="Send reply"
                      >
                        <Send className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
