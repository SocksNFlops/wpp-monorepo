"use client"

import { useState } from "react"
import { ChevronDown, ChevronUp, X, TrendingUp, BarChart3, DollarSign, Zap, PlusCircle, Info } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"
import { Badge } from "@/components/ui/badge"
import TokenIcon from "@/components/token-icon"

// Mock data for positions
const positions = [
  {
    id: 1,
    type: "Liquidity",
    name: "WETH++ / USDC",
    token1: {
      symbol: "WETH++",
      amount: "2.5",
      value: "$5,864.18",
      composition: {
        weth: 50,
        steth: 58,
      },
    },
    token2: { symbol: "USDC", amount: "6,481.49", value: "$6,481.49" },
    uniswapApr: "4.2%",
    bonusApr: "8.2%",
    totalApr: "12.4%",
    rewardsPlus: "$345.67",
    startDate: "2025-03-29",
    duration: "32 days",
    value: "$12,345.67",
  },
]

export default function PositionsPage() {
  const [expandedPosition, setExpandedPosition] = useState<number | null>(null)
  const [isCloseDialogOpen, setIsCloseDialogOpen] = useState(false)
  const [selectedPosition, setSelectedPosition] = useState<(typeof positions)[0] | null>(null)

  const toggleExpand = (positionId: number) => {
    if (expandedPosition === positionId) {
      setExpandedPosition(null)
    } else {
      setExpandedPosition(positionId)
    }
  }

  const handleClosePosition = (position: (typeof positions)[0]) => {
    setSelectedPosition(position)
    setIsCloseDialogOpen(true)
  }

  const totalValue = positions.reduce(
    (sum, position) => sum + Number.parseFloat(position.value.replace("$", "").replace(",", "")),
    0,
  )
  const totalRewardsPlus = positions.reduce(
    (sum, position) => sum + Number.parseFloat(position.rewardsPlus.replace("$", "").replace(",", "")),
    0,
  )

  // Calculate the underlying token amounts and values for WETH++
  const calculateUnderlyingTokens = (position: (typeof positions)[0]) => {
    if (position.token1.symbol === "WETH++") {
      const wethAmount = Number.parseFloat(position.token1.amount) * 0.5 // 50% WETH
      const stethAmount = Number.parseFloat(position.token1.amount) * 0.58 // 50% + 8% stETH

      // Calculate approximate values based on the total value
      const totalPositionValue = Number.parseFloat(position.token1.value.replace("$", "").replace(",", ""))
      const wethValue = totalPositionValue * (50 / 108) // 50% of the total value (adjusted for the extra 8%)
      const stethValue = totalPositionValue * (58 / 108) // 58% of the total value (adjusted for the extra 8%)

      return {
        weth: {
          amount: wethAmount.toFixed(2),
          value: `$${wethValue.toFixed(2)}`,
        },
        steth: {
          amount: stethAmount.toFixed(2),
          value: `$${stethValue.toFixed(2)}`,
        },
      }
    }
    return null
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <h1 className="text-2xl font-bold text-white">Your Positions</h1>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="glass-card border-gray-800">
          <CardHeader className="pb-2">
            <CardTitle className="text-lg flex items-center">
              <DollarSign size={18} className="mr-2 text-green-500" />
              Total Value
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">${totalValue.toLocaleString()}</div>
            <div className="text-sm text-gray-500">Across {positions.length} positions</div>
          </CardContent>
        </Card>

        <Card className="glass-card border-gray-800">
          <CardHeader className="pb-2">
            <CardTitle className="text-lg flex items-center">
              <Zap size={18} className="mr-2 text-purple-500" />
              Total Rewards++
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">${totalRewardsPlus.toLocaleString()}</div>
            <div className="text-sm text-gray-500">Enhanced rewards from all positions</div>
          </CardContent>
        </Card>

        <Card className="glass-card border-gray-800">
          <CardHeader className="pb-2">
            <CardTitle className="text-lg flex items-center">
              <BarChart3 size={18} className="mr-2 text-blue-500" />
              Average APR
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-white">12.4%</div>
            <div className="text-sm text-gray-500">Combined APR (Uniswap + Bonus)</div>
          </CardContent>
        </Card>
      </div>

      <div className="space-y-4">
        {positions.length > 0 ? (
          positions.map((position) => (
            <Card key={position.id} className="glass-card border-gray-800 overflow-hidden">
              <div className="cursor-pointer" onClick={() => toggleExpand(position.id)}>
                <CardHeader className="pb-3">
                  <div className="flex justify-between items-center">
                    <div className="flex items-center gap-3">
                      <div className="flex">
                        <TokenIcon symbol={position.token1.symbol} size={28} />
                        <TokenIcon symbol={position.token2.symbol} size={28} className="-ml-1" />
                      </div>
                      <div>
                        <CardTitle className="text-xl text-white">{position.name}</CardTitle>
                        <CardDescription>{position.type} Position</CardDescription>
                      </div>
                    </div>
                    <div className="hidden md:block">
                      {expandedPosition === position.id ? (
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
                      <div className="text-sm text-gray-500">Value</div>
                      <div className="font-medium text-white">{position.value}</div>
                    </div>

                    <div>
                      <div className="text-sm text-gray-500">APR Breakdown</div>
                      <div className="font-medium text-white flex items-center gap-1">
                        <TooltipProvider>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <div className="flex items-center">
                                <span className="text-blue-400">{position.uniswapApr}</span>
                                <span className="mx-1">+</span>
                                <span className="text-purple-400">{position.bonusApr}</span>
                              </div>
                            </TooltipTrigger>
                            <TooltipContent>
                              <div className="text-xs space-y-1">
                                <div className="flex items-center">
                                  <div className="w-2 h-2 rounded-full bg-blue-400 mr-2"></div>
                                  <span>Uniswap Fees: {position.uniswapApr}</span>
                                </div>
                                <div className="flex items-center">
                                  <div className="w-2 h-2 rounded-full bg-purple-400 mr-2"></div>
                                  <span>Bonus APR: {position.bonusApr}</span>
                                </div>
                              </div>
                            </TooltipContent>
                          </Tooltip>
                        </TooltipProvider>
                        <TrendingUp size={14} className="ml-1 text-green-500" />
                      </div>
                    </div>

                    <div>
                      <div className="text-sm text-gray-500">Rewards++</div>
                      <div className="font-medium text-white flex items-center">
                        {position.rewardsPlus}
                        <Zap size={14} className="ml-1 text-purple-500" />
                      </div>
                    </div>

                    <div>
                      <div className="text-sm text-gray-500">Duration</div>
                      <div className="font-medium text-white">{position.duration}</div>
                    </div>
                  </div>
                </CardContent>
              </div>

              {expandedPosition === position.id && (
                <div className="border-t border-gray-800 px-6 py-4 bg-gray-900/50">
                  <div className="space-y-6">
                    <div>
                      <div className="text-sm font-medium mb-2">Position Breakdown</div>

                      <div className="space-y-4">
                        <div className="space-y-2">
                          <div className="flex justify-between text-sm">
                            <span>{position.token1.symbol}</span>
                            <span>
                              {position.token1.amount} ({position.token1.value})
                            </span>
                          </div>
                          <Progress
                            value={
                              (Number.parseFloat(position.token1.value.replace("$", "").replace(",", "")) /
                                Number.parseFloat(position.value.replace("$", "").replace(",", ""))) *
                              100
                            }
                            className="h-2 bg-gray-800"
                          />

                          {position.token2 && (
                            <>
                              <div className="flex justify-between text-sm">
                                <span>{position.token2.symbol}</span>
                                <span>
                                  {position.token2.amount} ({position.token2.value})
                                </span>
                              </div>
                              <Progress
                                value={
                                  (Number.parseFloat(position.token2.value.replace("$", "").replace(",", "")) /
                                    Number.parseFloat(position.value.replace("$", "").replace(",", ""))) *
                                  100
                                }
                                className="h-2 bg-gray-800"
                              />
                            </>
                          )}
                        </div>

                        <div className="bg-gray-900 rounded-md p-4 border border-gray-800">
                          <div className="flex items-center justify-between mb-3">
                            <div className="text-sm font-medium flex items-center">
                              <span className="text-white">WETH++ Composition</span>
                              <Badge
                                variant="outline"
                                className="ml-2 bg-purple-900/30 text-purple-300 border-purple-800"
                              >
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
                                    WETH++ generates extra yield, allowing you to withdraw more than you deposited. The
                                    extra 8% stETH represents your accumulated yield.
                                  </p>
                                </TooltipContent>
                              </Tooltip>
                            </TooltipProvider>
                          </div>

                          <div className="space-y-3">
                            <div>
                              <div className="flex justify-between text-sm mb-1">
                                <span>WETH</span>
                                <span>{position.token1.composition.weth}%</span>
                              </div>
                              <Progress value={position.token1.composition.weth} className="h-2 bg-gray-800" />
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
                                  style={{ width: `${position.token1.composition.steth}%` }}
                                ></div>
                              </div>
                            </div>

                            <div className="pt-2 border-t border-gray-800">
                              <div className="flex justify-between text-sm">
                                <span>Total</span>
                                <span className="font-medium">{position.token1.composition.weth + 50}%</span>
                              </div>
                              <div className="text-xs text-green-500 mt-1">
                                You'll receive extra stETH when you withdraw!
                              </div>
                            </div>
                          </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                          <div>
                            <div className="text-sm text-gray-500 mb-1">Start Date</div>
                            <div className="text-sm">{new Date(position.startDate).toLocaleDateString()}</div>
                          </div>

                          <div>
                            <div className="text-sm text-gray-500 mb-1">Rewards++ Rate</div>
                            <div className="text-sm flex items-center">
                              $
                              {(
                                Number.parseFloat(position.rewardsPlus.replace("$", "").replace(",", "")) /
                                Number.parseInt(position.duration)
                              ).toFixed(2)}{" "}
                              / day
                              <Zap size={12} className="ml-1 text-purple-500" />
                            </div>
                          </div>

                          <div>
                            <div className="text-sm text-gray-500 mb-1">Actions</div>
                            <div className="flex items-center gap-2">
                              <Button
                                size="sm"
                                variant="destructive"
                                className="bg-red-900 hover:bg-red-800 text-white"
                                onClick={(e) => {
                                  e.stopPropagation()
                                  handleClosePosition(position)
                                }}
                              >
                                <X size={14} className="mr-1" />
                                Close Position
                              </Button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div>
                      <div className="text-sm font-medium mb-2">APR Breakdown</div>
                      <div className="bg-gray-900 rounded-md p-4">
                        <div className="space-y-3">
                          <div>
                            <div className="flex justify-between text-sm mb-1">
                              <span className="flex items-center">
                                <div className="w-2 h-2 rounded-full bg-blue-400 mr-2"></div>
                                Uniswap Fees APR
                              </span>
                              <span>{position.uniswapApr}</span>
                            </div>
                            <Progress value={Number.parseFloat(position.uniswapApr)} className="h-2 bg-gray-800" />
                          </div>

                          <div>
                            <div className="flex justify-between text-sm mb-1">
                              <span className="flex items-center">
                                <div className="w-2 h-2 rounded-full bg-purple-400 mr-2"></div>
                                Bonus APR from Weth++
                              </span>
                              <span>{position.bonusApr}</span>
                            </div>
                            <Progress value={Number.parseFloat(position.bonusApr)} className="h-2 bg-gray-800" />
                          </div>

                          <div className="pt-2 border-t border-gray-800">
                            <div className="flex justify-between text-sm">
                              <span>Total APR</span>
                              <span className="font-medium">{position.totalApr}</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </Card>
          ))
        ) : (
          <Card className="glass-card border-gray-800 p-6">
            <div className="text-center py-8">
              <div className="text-4xl mb-4">🔍</div>
              <h3 className="text-xl font-medium text-white mb-2">No positions found</h3>
              <p className="text-gray-500 mb-4">You don't have any positions yet.</p>
              <Button>Create Position</Button>
            </div>
          </Card>
        )}
      </div>

      <Dialog open={isCloseDialogOpen} onOpenChange={setIsCloseDialogOpen}>
        <DialogContent className="glass-card border-gray-800 sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-xl text-white">Close Position</DialogTitle>
            <DialogDescription>
              Are you sure you want to close this position? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>

          {selectedPosition && (
            <div className="space-y-4 py-2">
              <div className="flex items-center gap-3">
                <div className="flex">
                  <TokenIcon symbol={selectedPosition.token1.symbol} size={28} />
                  <TokenIcon symbol={selectedPosition.token2.symbol} size={28} className="-ml-1" />
                </div>
                <div>
                  <div className="font-medium text-white">{selectedPosition.name}</div>
                  <div className="text-sm text-gray-500">{selectedPosition.type} Position</div>
                </div>
              </div>

              <Alert variant="destructive" className="bg-red-900/30 border-red-900 text-red-300">
                <AlertDescription>
                  Closing this position will withdraw all your tokens and claim any unclaimed Rewards++.
                </AlertDescription>
              </Alert>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <div className="text-sm text-gray-500">Position Value</div>
                  <div className="font-medium text-white">{selectedPosition.value}</div>
                </div>
                <div>
                  <div className="text-sm text-gray-500">Unclaimed Rewards++</div>
                  <div className="font-medium text-white flex items-center">
                    {selectedPosition.rewardsPlus}
                    <Zap size={14} className="ml-1 text-purple-500" />
                  </div>
                </div>
              </div>

              <div className="text-sm text-gray-500">
                You will receive:
                <div className="grid grid-cols-1 gap-2 mt-2">
                  {selectedPosition.token1.symbol === "WETH++" && (
                    <>
                      <div className="flex justify-between items-center p-2 bg-gray-900 rounded-md">
                        <span className="flex items-center">
                          <TokenIcon symbol="WETH" size={16} className="mr-1" />
                          1.25 WETH
                        </span>
                        <span>$2,932.09</span>
                      </div>
                      <div className="flex justify-between items-center p-2 bg-gray-900 rounded-md">
                        <span className="flex items-center">
                          <TokenIcon symbol="stETH" size={16} className="mr-1" />
                          1.45 stETH
                        </span>
                        <span>$2,932.09</span>
                      </div>
                    </>
                  )}
                  <div className="flex justify-between items-center p-2 bg-gray-900 rounded-md">
                    <span className="flex items-center">
                      <TokenIcon symbol={selectedPosition.token2.symbol} size={16} className="mr-1" />
                      {selectedPosition.token2.amount} {selectedPosition.token2.symbol}
                    </span>
                    <span>{selectedPosition.token2.value}</span>
                  </div>
                </div>
              </div>

              <div className="bg-gray-900 p-3 rounded-md border border-green-900/50">
                <div className="text-sm text-green-500 font-medium mb-1 flex items-center">
                  <PlusCircle size={14} className="mr-1" />
                  Extra stETH Bonus
                </div>
                <div className="text-xs text-gray-300">
                  Your WETH++ includes 8% extra stETH yield that you'll receive when withdrawing!
                </div>
              </div>
            </div>
          )}

          <DialogFooter className="flex flex-col sm:flex-row gap-2">
            <Button
              variant="outline"
              className="w-full sm:w-auto border-gray-700 hover:bg-gray-800"
              onClick={() => setIsCloseDialogOpen(false)}
            >
              Cancel
            </Button>
            <Button variant="destructive" className="w-full sm:w-auto bg-red-900 hover:bg-red-800">
              Close Position
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

