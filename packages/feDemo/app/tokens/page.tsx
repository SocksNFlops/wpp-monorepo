"use client"

import { useState } from "react"
import { Search, TrendingUp, ChevronDown, ChevronUp, Info, ExternalLink, PlusCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Progress } from "@/components/ui/progress"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"
import { Badge } from "@/components/ui/badge"
import TokenIcon from "@/components/token-icon"

// Mock data for tokens
const tokens = [
  {
    id: 1,
    name: "WETH++",
    symbol: "WETH++",
    price: "$2,345.67",
    priceChange: "+5.2%",
    marketCap: "$1.2B",
    volume24h: "$234.5M",
    composition: {
      weth: 50,
      steth: 58,
    },
    currentYield: "8.4%",
    description: "Enhanced yield-bearing version of Wrapped Ethereum",
  },
  {
    id: 2,
    name: "WBTC++",
    symbol: "WBTC++",
    price: "$42,345.67",
    priceChange: "+3.8%",
    marketCap: "$980M",
    volume24h: "$156.7M",
    composition: {
      raw: 60,
      earn: 40,
    },
    currentYield: "6.2%",
    description: "Enhanced yield-bearing version of Wrapped Bitcoin",
  },
  {
    id: 3,
    name: "USDT++",
    symbol: "USDT++",
    price: "$1.00",
    priceChange: "+0.1%",
    marketCap: "$750M",
    volume24h: "$123.4M",
    composition: {
      raw: 50,
      earn: 50,
    },
    currentYield: "12.5%",
    description: "Enhanced yield-bearing version of Tether USD",
  },
  {
    id: 4,
    name: "USDC++",
    symbol: "USDC++",
    price: "$1.00",
    priceChange: "+0.05%",
    marketCap: "$680M",
    volume24h: "$98.7M",
    composition: {
      raw: 45,
      earn: 55,
    },
    currentYield: "11.8%",
    description: "Enhanced yield-bearing version of USD Coin",
  },
]

export default function TokensPage() {
  const [searchQuery, setSearchQuery] = useState("")
  const [expandedToken, setExpandedToken] = useState<number | null>(null)

  const filteredTokens = tokens.filter(
    (token) =>
      token.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      token.symbol.toLowerCase().includes(searchQuery.toLowerCase()),
  )

  const toggleExpand = (tokenId: number) => {
    if (expandedToken === tokenId) {
      setExpandedToken(null)
    } else {
      setExpandedToken(tokenId)
    }
  }

  const renderTokenComposition = (token: (typeof tokens)[0]) => {
    if (token.symbol === "WETH++") {
      return (
        <div className="bg-gray-900 rounded-md p-4 border border-gray-800">
          <div className="flex items-center justify-between mb-3">
            <div className="text-sm font-medium flex items-center">
              <span className="text-white">WETH++ Composition</span>
              <Badge variant="outline" className="ml-2 bg-purple-900/30 text-purple-300 border-purple-800">
                <PlusCircle size={12} className="mr-1" /> Extra Yield
              </Badge>
            </div>
            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger asChild>
                  <div className="text-xs text-gray-500 flex items-center cursor-help">
                    <span>Why over 100%?</span>
                    <Info size={12} className="ml-1" />
                  </div>
                </TooltipTrigger>
                <TooltipContent className="max-w-[250px]">
                  <p className="text-xs">
                    WETH++ generates extra yield, allowing you to withdraw more than you deposited. The extra 8% stETH
                    represents your accumulated yield.
                  </p>
                </TooltipContent>
              </Tooltip>
            </TooltipProvider>
          </div>

          <div className="space-y-3">
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span>WETH</span>
                <span>{token.composition.weth}%</span>
              </div>
              <Progress value={token.composition.weth} className="h-2 bg-gray-800" />
            </div>

            <div>
              <div className="flex justify-between text-sm mb-1">
                <span>stETH</span>
                <span className="flex items-center">
                  50%
                  <span className="text-green-500 text-xs ml-1">+8%</span>
                </span>
              </div>
              <div className="relative">
                <Progress value={50} className="h-2 bg-gray-800" />
                <div
                  className="absolute top-0 left-0 h-2 bg-green-500/30 rounded-r-sm"
                  style={{ width: `${token.composition.steth}%` }}
                ></div>
              </div>
            </div>

            <div className="pt-2 border-t border-gray-800">
              <div className="flex justify-between text-sm">
                <span>Total</span>
                <span className="font-medium">{token.composition.weth + 50}%</span>
              </div>
              <div className="text-xs text-green-500 mt-1">You'll receive extra stETH when you withdraw!</div>
            </div>
          </div>
        </div>
      )
    } else {
      return (
        <div className="space-y-2">
          <div className="flex justify-between text-sm">
            <span>Raw {token.symbol.replace("++", "")}</span>
            <span>{token.composition.raw}%</span>
          </div>
          <Progress value={token.composition.raw} className="h-2 bg-gray-800" />

          <div className="flex justify-between text-sm">
            <span>Earn {token.symbol.replace("++", "")}</span>
            <span>{token.composition.earn}%</span>
          </div>
          <Progress value={token.composition.earn} className="h-2 bg-gray-800" />
        </div>
      )
    }
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <h1 className="text-2xl font-bold text-white">PlusPlus Tokens</h1>

        <div className="relative w-full md:w-auto">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500" size={18} />
          <Input
            placeholder="Search tokens..."
            className="pl-10 bg-gray-900 border-gray-800 w-full md:w-[300px]"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      <div className="space-y-4">
        {filteredTokens.map((token) => (
          <Card key={token.id} className="glass-card border-gray-800 overflow-hidden">
            <div className="cursor-pointer" onClick={() => toggleExpand(token.id)}>
              <CardHeader className="pb-3">
                <div className="flex justify-between items-center">
                  <div className="flex items-center gap-3">
                    <TokenIcon symbol={token.symbol} size={32} />
                    <div>
                      <CardTitle className="text-xl text-white">{token.name}</CardTitle>
                      <CardDescription>{token.description}</CardDescription>
                    </div>
                  </div>
                  <div className="hidden md:block">
                    {expandedToken === token.id ? (
                      <ChevronUp size={20} className="text-gray-500" />
                    ) : (
                      <ChevronDown size={20} className="text-gray-500" />
                    )}
                  </div>
                </div>
              </CardHeader>

              <CardContent className="pb-4">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div>
                    <div className="text-sm text-gray-500">Price</div>
                    <div className="font-medium text-white">{token.price}</div>
                    <div className={`text-xs ${token.priceChange.startsWith("+") ? "text-green-500" : "text-red-500"}`}>
                      {token.priceChange}
                    </div>
                  </div>

                  <div>
                    <div className="text-sm text-gray-500">Market Cap</div>
                    <div className="font-medium text-white">{token.marketCap}</div>
                  </div>

                  <div>
                    <div className="text-sm text-gray-500">24h Volume</div>
                    <div className="font-medium text-white">{token.volume24h}</div>
                  </div>

                  <div>
                    <div className="text-sm text-gray-500">Current Yield</div>
                    <div className="font-medium text-white flex items-center">
                      {token.currentYield}
                      <TrendingUp size={14} className="ml-1 text-green-500" />
                    </div>
                  </div>
                </div>
              </CardContent>
            </div>

            {expandedToken === token.id && (
              <div className="border-t border-gray-800 px-6 py-4 bg-gray-900/50">
                <div className="space-y-6">
                  <div>
                    <div className="flex justify-between items-center mb-2">
                      <div className="text-sm font-medium">Token Composition</div>
                      <TooltipProvider>
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Info size={14} className="text-gray-500 cursor-help" />
                          </TooltipTrigger>
                          <TooltipContent>
                            <p className="w-[200px] text-xs">
                              PlusPlus tokens are composed of raw tokens and yield-generating positions.
                            </p>
                          </TooltipContent>
                        </Tooltip>
                      </TooltipProvider>
                    </div>

                    {renderTokenComposition(token)}
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                      <div className="text-sm text-gray-500 mb-1">Yield Source</div>
                      <div className="flex items-center gap-2">
                        <Badge variant="outline" className="bg-gray-800 text-gray-300">
                          Lending
                        </Badge>
                        <Badge variant="outline" className="bg-gray-800 text-gray-300">
                          Staking
                        </Badge>
                      </div>
                    </div>

                    <div>
                      <div className="text-sm text-gray-500 mb-1">Protocol Risk</div>
                      <div className="flex items-center gap-1">
                        <span className="w-2 h-2 rounded-full bg-green-500"></span>
                        <span className="text-sm">Low</span>
                      </div>
                    </div>

                    <div>
                      <div className="text-sm text-gray-500 mb-1">Actions</div>
                      <div className="flex items-center gap-2">
                        <Button size="sm" variant="outline" className="border-gray-700 hover:bg-gray-800">
                          Mint
                        </Button>
                        <Button size="sm" variant="outline" className="border-gray-700 hover:bg-gray-800">
                          Redeem
                        </Button>
                        <Button size="sm" variant="ghost" className="text-gray-400 hover:text-white">
                          <ExternalLink size={14} />
                        </Button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </Card>
        ))}
      </div>
    </div>
  )
}

