import Image from "next/image"

interface TokenIconProps {
  symbol: string
  size?: number
  className?: string
}

export default function TokenIcon({ symbol, size = 24, className = "" }: TokenIconProps) {
  // Map of token symbols to their image paths or emoji fallbacks
  const tokenIcons: Record<string, { type: "image" | "emoji"; value: string }> = {
    "WETH++": { type: "image", value: "/images/weth-plus-plus.svg" },
    WETH: { type: "image", value: "/images/ethereum-eth.svg" },
    stETH: { type: "image", value: "/images/stETH_ug10fg.svg" },
    "WBTC++": { type: "image", value: "/images/wrapped-bitcoin-wbtc-icon.svg" },
    WBTC: { type: "image", value: "/images/wrapped-bitcoin-wbtc-icon.svg" },
    USDC: { type: "image", value: "/images/usd-coin-usdc-logo.svg" },
    "USDC++": { type: "image", value: "/images/usd-coin-usdc-logo.svg" },
    USDT: { type: "image", value: "/images/usdt-svgrepo-com.svg" },
    "USDT++": { type: "image", value: "/images/usdt-svgrepo-com.svg" },
    sBTC: { type: "emoji", value: "🟡" },
    aUSDT: { type: "emoji", value: "💱" },
  }

  const icon = tokenIcons[symbol] || { type: "emoji", value: "💰" } // Default fallback

  if (icon.type === "image") {
    return (
      <div className={`inline-flex items-center justify-center ${className}`} style={{ width: size, height: size }}>
        <Image
          src={icon.value || "/placeholder.svg"}
          alt={symbol}
          width={size}
          height={size}
          className="object-contain"
        />
      </div>
    )
  }

  return (
    <span className={`inline-flex items-center justify-center ${className}`} style={{ fontSize: size * 0.8 }}>
      {icon.value}
    </span>
  )
}

