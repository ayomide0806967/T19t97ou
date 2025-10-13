import { MessageCircle, Repeat2, Heart, Share2 } from "lucide-react";

export default function TweetCard() {
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
        </div>
      </div>
    </div>
  );
}
