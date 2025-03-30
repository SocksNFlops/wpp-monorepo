"use client"

import { useState } from "react"
import { ArrowRightLeft, Plus, TrendingUp, Info } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"
import { useRouter } from "next/navigation"
import TokenIcon from "@/components/token-icon"

// Mock data for pools
const pools = [
  {
    id: 1,
    name: "WETH++ / USDC",
    tvl: "$4,235,612",
    apr: "12.4%",
    volume24h: "$1,245,678",
    token1: {
      symbol: "WETH++",
      balance: "0.00",
      underlying: [
        { symbol: "WETH", balance: "0.00" },
        { symbol: "stETH", balance: "0.00" },
      ],
    },
    token2: { symbol: "USDC", balance: "0.00" },
  },
  {
    id: 2,
    name: "WBTC++ / USDC",
    tvl: "$2,876,321",
    apr: "9.8%",
    volume24h: "$876,543",
    token1: {
      symbol: "WBTC++",
      balance: "0.00",
      underlying: [
        { symbol: "WBTC", balance: "0.00" },
        { symbol: "sBTC", balance: "0.00" },
      ],
    },
    token2: { symbol: "USDC", balance: "0.00" },
  },
  {
    id: 3,
    name: "USDT++ / USDC",
    tvl: "$1,987,654",
    apr: "8.2%",
    volume24h: "$654,321",
    token1: {
      symbol: "USDT++",
      balance: "0.00",
      underlying: [
        { symbol: "USDT", balance: "0.00" },
        { symbol: "aUSDT", balance: "0.00" },
      ],
    },
    token2: { symbol: "USDC", balance: "0.00" },
  },
]

export default function PoolsPage() {
  const [selectedPool, setSelectedPool] = useState(pools[0])
  const [activeTab, setActiveTab] = useState("swap")
  const [amount, setAmount] = useState("")
  const [fromToken, setFromToken] = useState("WETH")
  const [toToken, setToToken] = useState("USDC")
  const [provideToken1, setProvideToken1] = useState("WETH")
  const [provideToken2, setProvideToken2] = useState("USDC")
  const [provideAmount1, setProvideAmount1] = useState("")
  const [provideAmount2, setProvideAmount2] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()

  const handlePoolSelect = (poolId: number) => {
    const pool = pools.find((p) => p.id === poolId)
    if (pool) {
      setSelectedPool(pool)
      // Reset tokens to default when changing pools
      if (pool.token1.symbol === "WETH++") {
        setFromToken("WETH")
        setProvideToken1("WETH")
      } else if (pool.token1.symbol === "WBTC++") {
        setFromToken("WBTC")
        setProvideToken1("WBTC")
      } else if (pool.token1.symbol === "USDT++") {
        setFromToken("USDT")
        setProvideToken1("USDT")
      }
      setToToken("USDC")
      setProvideToken2("USDC")
    }
  }

  const handleSwapTokens = () => {
    const temp = fromToken
    setFromToken(toToken)
    setToToken(temp)
  }

  const getExchangeRate = () => {
    // Mock exchange rates
    const rates: Record<string, number> = {
      "WETH-USDC": 1800,
      "stETH-USDC": 1790,
      "WBTC-USDC": 28000,
      "sBTC-USDC": 27800,
      "USDT-USDC": 1,
      "aUSDT-USDC": 1,
      "USDC-WETH": 1 / 1800,
      "USDC-stETH": 1 / 1790,
      "USDC-WBTC": 1 / 28000,
      "USDC-sBTC": 1 / 27800,
      "USDC-USDT": 1,
      "USDC-aUSDT": 1,
      "WETH-stETH": 1.01,
      "stETH-WETH": 0.99,
      "WBTC-sBTC": 1.01,
      "sBTC-WBTC": 0.99,
      "USDT-aUSDT": 1.01,
      "aUSDT-USDT": 0.99,
    }

    const pair = `${fromToken}-${toToken}`
    return rates[pair] || 1
  }

  const getTokenBalance = (tokenSymbol: string) => {
    if (tokenSymbol === "USDC") return selectedPool.token2.balance

    const underlying = selectedPool.token1.underlying.find((t) => t.symbol === tokenSymbol)
    if (underlying) return underlying.balance

    return "0.00" // Default fallback
  }

  const getAvailableFromTokens = () => {
    if (selectedPool.token1.symbol === "WETH++") {
      return ["WETH", "stETH", "USDC"]
    } else if (selectedPool.token1.symbol === "WBTC++") {
      return ["WBTC", "sBTC", "USDC"]
    } else {
      return [selectedPool.token1.underlying[0].symbol, selectedPool.token1.underlying[1].symbol, "USDC"]
    }
  }

  const getAvailableToTokens = () => {
    return getAvailableFromTokens().filter((t) => t !== fromToken)
  }

  const getAvailableProvideTokens1 = () => {
    if (selectedPool.token1.symbol === "WETH++") {
      return ["WETH", "stETH"]
    } else if (selectedPool.token1.symbol === "WBTC++") {
      return ["WBTC", "sBTC"]
    } else {
      return [selectedPool.token1.underlying[0].symbol, selectedPool.token1.underlying[1].symbol]
    }
  }

  const handleProvide = () => {
    setIsLoading(true)
    setTimeout(() => {
      setIsLoading(false)
      router.push("/positions")
    }, 3000)
  }

  const calculateProvideAmount2 = () => {
    if (!provideAmount1) return ""

    // Mock exchange rates for providing liquidity
    const rates: Record<string, number> = {
      "WETH-USDC": 1800,
      "stETH-USDC": 1790,
      "WBTC-USDC": 28000,
      "sBTC-USDC": 27800,
      "USDT-USDC": 1,
      "aUSDT-USDC": 1,
    }

    const pair = `${provideToken1}-${provideToken2}`
    const rate = rates[pair] || 1

    return (Number.parseFloat(provideAmount1) * rate).toFixed(2)
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col md:flex-row gap-6">
        <div className="w-full md:w-2/3 space-y-6">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-white">Liquidity Pools</h1>
            <Button variant="outline" className="border-gray-700 hover:bg-gray-800">
              <Plus size={16} className="mr-2" />
              Create Pool
            </Button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {pools.map((pool) => (
              <Card
                key={pool.id}
                className={`glass-card hover:border-gray-700 transition-all cursor-pointer ${
                  selectedPool.id === pool.id ? "gradient-border" : ""
                }`}
                onClick={() => handlePoolSelect(pool.id)}
              >
                <CardHeader className="pb-2">
                  <CardTitle className="text-lg flex items-center">
                    <TokenIcon symbol={pool.token1.symbol} size={24} className="mr-2" />
                    <TokenIcon symbol={pool.token2.symbol} size={24} className="mr-2" />
                    {pool.name}
                  </CardTitle>
                  <CardDescription>
                    <div className="flex items-center">
                      <TrendingUp size={14} className="mr-1 text-green-500" />
                      APR: {pool.apr}
                    </div>
                  </CardDescription>
                </CardHeader>
                <CardContent className="pb-2">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <div className="text-gray-500">TVL</div>
                      <div className="font-medium">{pool.tvl}</div>
                    </div>
                    <div>
                      <div className="text-gray-500">24h Volume</div>
                      <div className="font-medium">{pool.volume24h}</div>
                    </div>
                  </div>
                </CardContent>
                <CardFooter className="pt-0">
                  <Button
                    variant="ghost"
                    size="sm"
                    className="w-full text-xs hover:bg-gray-800 text-gray-400 hover:text-white"
                  >
                    View Details
                  </Button>
                </CardFooter>
              </Card>
            ))}
          </div>
        </div>

        <div className="w-full md:w-1/3">
          <Card className="glass-card border-gray-800">
            <CardHeader>
              <CardTitle className="text-xl flex items-center justify-between">
                <span>{selectedPool.name}</span>
                <TooltipProvider>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Info size={16} className="text-gray-500 cursor-help" />
                    </TooltipTrigger>
                    <TooltipContent>
                      <p className="w-[200px] text-xs">
                        PlusPlus tokens are enhanced yield-bearing versions of existing tokens.
                      </p>
                    </TooltipContent>
                  </Tooltip>
                </TooltipProvider>
              </CardTitle>
              <CardDescription>
                <div className="flex items-center justify-between">
                  <span>APR: {selectedPool.apr}</span>
                  <span>TVL: {selectedPool.tvl}</span>
                </div>
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
                <TabsList className="grid w-full grid-cols-2 bg-gray-900">
                  <TabsTrigger value="swap" className="data-[state=active]:bg-gray-800">
                    <ArrowRightLeft size={16} className="mr-2" />
                    Swap
                  </TabsTrigger>
                  <TabsTrigger value="provide" className="data-[state=active]:bg-gray-800">
                    <Plus size={16} className="mr-2" />
                    Provide
                  </TabsTrigger>
                </TabsList>

                <TabsContent value="swap" className="space-y-4 pt-4">
                  <div className="space-y-4">
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <label>From</label>
                        <span className="text-gray-500">Balance: {getTokenBalance(fromToken)}</span>
                      </div>
                      <div className="flex space-x-2">
                        <Input
                          type="number"
                          placeholder="0.0"
                          value={amount}
                          onChange={(e) => setAmount(e.target.value)}
                          className="bg-gray-900 border-gray-800"
                        />
                        <Select value={fromToken} onValueChange={setFromToken}>
                          <SelectTrigger className="w-[120px] bg-gray-900 border-gray-800">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent className="bg-gray-900 border-gray-800">
                            {getAvailableFromTokens().map((token) => (
                              <SelectItem key={token} value={token}>
                                <div className="flex items-center">
                                  <TokenIcon symbol={token} size={20} className="mr-2" />
                                  {token}
                                </div>
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    </div>

                    <div className="flex justify-center">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={handleSwapTokens}
                        className="rounded-full bg-gray-900 hover:bg-gray-800"
                      >
                        <ArrowRightLeft size={16} />
                      </Button>
                    </div>

                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <label>To</label>
                        <span className="text-gray-500">Balance: {getTokenBalance(toToken)}</span>
                      </div>
                      <div className="flex space-x-2">
                        <Input
                          type="number"
                          placeholder="0.0"
                          value={amount ? (Number.parseFloat(amount) * getExchangeRate()).toFixed(6) : ""}
                          disabled
                          className="bg-gray-900 border-gray-800"
                        />
                        <Select value={toToken} onValueChange={setToToken}>
                          <SelectTrigger className="w-[120px] bg-gray-900 border-gray-800">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent className="bg-gray-900 border-gray-800">
                            {getAvailableToTokens().map((token) => (
                              <SelectItem key={token} value={token}>
                                <div className="flex items-center">
                                  <TokenIcon symbol={token} size={20} className="mr-2" />
                                  {token}
                                </div>
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    </div>

                    <div className="pt-2">
                      <Button className="w-full bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700">
                        Swap Tokens
                      </Button>
                    </div>

                    <div className="text-xs text-gray-500 space-y-1 pt-2">
                      <div className="flex justify-between">
                        <span>Price:</span>
                        <span>
                          1 {fromToken} = {getExchangeRate()} {toToken}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Price Impact:</span>
                        <span>0.05%</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Route:</span>
                        <span>Direct</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Fee:</span>
                        <span>0.3%</span>
                      </div>
                    </div>
                  </div>
                </TabsContent>

                <TabsContent value="provide" className="space-y-4 pt-4">
                  <div className="space-y-4">
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <label>You provide</label>
                        <span className="text-gray-500">Balance: {getTokenBalance(provideToken1)}</span>
                      </div>
                      <div className="flex space-x-2">
                        <Input
                          type="number"
                          placeholder="0.0"
                          className="bg-gray-900 border-gray-800"
                          value={provideAmount1}
                          onChange={(e) => setProvideAmount1(e.target.value)}
                        />
                        <Select value={provideToken1} onValueChange={setProvideToken1}>
                          <SelectTrigger className="w-[120px] bg-gray-900 border-gray-800">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent className="bg-gray-900 border-gray-800">
                            {getAvailableProvideTokens1().map((token) => (
                              <SelectItem key={token} value={token}>
                                <div className="flex items-center">
                                  <TokenIcon symbol={token} size={20} className="mr-2" />
                                  {token}
                                </div>
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    </div>

                    <div className="flex justify-center">
                      <Plus size={16} className="text-gray-500" />
                    </div>

                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <label>{selectedPool.token2.symbol}</label>
                        <span className="text-gray-500">Balance: {selectedPool.token2.balance}</span>
                      </div>
                      <div className="flex space-x-2">
                        <Input
                          type="number"
                          placeholder="0.0"
                          className="bg-gray-900 border-gray-800"
                          value={calculateProvideAmount2()}
                          disabled
                        />
                        <Select value={provideToken2} onValueChange={setProvideToken2} disabled>
                          <SelectTrigger className="w-[120px] bg-gray-900 border-gray-800">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent className="bg-gray-900 border-gray-800">
                            <SelectItem value="USDC">
                              <div className="flex items-center">
                                <TokenIcon symbol="USDC" size={20} className="mr-2" />
                                USDC
                              </div>
                            </SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>

                    <div className="pt-2">
                      <Button
                        className="w-full bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700"
                        disabled={isLoading || !provideAmount1}
                        onClick={handleProvide}
                      >
                        {isLoading ? (
                          <div className="flex items-center justify-center">
                            <svg
                              className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                              xmlns="http://www.w3.org/2000/svg"
                              fill="none"
                              viewBox="0 0 24 24"
                            >
                              <circle
                                className="opacity-25"
                                cx="12"
                                cy="12"
                                r="10"
                                stroke="currentColor"
                                strokeWidth="4"
                              ></circle>
                              <path
                                className="opacity-75"
                                fill="currentColor"
                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                              ></path>
                            </svg>
                            Processing...
                          </div>
                        ) : (
                          "Provide Liquidity"
                        )}
                      </Button>
                    </div>

                    <div className="text-xs text-gray-500 space-y-1 pt-2">
                      <div className="flex justify-between">
                        <span>Share of Pool:</span>
                        <span>0.00%</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Expected APR:</span>
                        <span>{selectedPool.apr}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>You'll receive:</span>
                        <span className="flex items-center">
                          <TokenIcon symbol={selectedPool.token1.symbol} size={14} className="mr-1" />
                          {selectedPool.token1.symbol} LP tokens
                        </span>
                      </div>
                    </div>
                  </div>
                </TabsContent>
              </Tabs>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}

