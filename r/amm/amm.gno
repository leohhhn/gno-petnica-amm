package amm

import (
	"std"

	"gno.land/p/demo/ufmt"
	ptn "gno.land/r/petnica/coin"
)

var (
	bank    std.Banker
	this    std.Realm
	lpUgnot int64
	lpPtn   int64
)

func init() {
	bank = std.GetBanker(std.BankerTypeRealmSend)
	this = std.CurrentRealm()
}

func AddLP() string {
	sentCoins := std.GetOrigSend()
	sentPtn := sentCoins.AmountOf(ptn.ExternalPtnDenom)
	sentUgnot := sentCoins.AmountOf("ugnot")

	if sentUgnot < 0 || sentPtn < 0 {
		panic("you need to provide both ptn and ugnot to the liq. pool")
	}

	lp := bank.GetCoins(this.Addr())
	lpPtn = lp.AmountOf(ptn.ExternalPtnDenom)
	lpUgnot = lp.AmountOf("ugnot")

	return ufmt.Sprintf("ugnot: %d, ptn: %d", lpUgnot, lpPtn)
}

// Swap swaps $ptn & $ugnot based on the ratio currently found in the balance of this realm
// Swap works on the simple formula k = y * x
// Swap takes only one or the other coin as send arguments
func Swap() std.Coin {
	sentCoins := std.GetOrigSend()
	sentPtn := sentCoins.AmountOf(ptn.ExternalPtnDenom)
	sentUgnot := sentCoins.AmountOf("ugnot")

	// Determine swap type
	ugnotSwap := sentUgnot > 0
	ptnSwap := sentPtn > 0

	// Check if only one coin was sent
	if ptnSwap == ugnotSwap {
		panic("you must send only $ptn or only $ugnot to swap")
	}

	// Check liquidity
	if lpPtn == 0 || lpUgnot == 0 {
		panic("not enough liquidity for ptn or ugnot")
	}

	k := lpPtn * lpUgnot // current LP formula
	caller := std.PrevRealm().Addr()

	// Swapping ugnot for ptn
	if ugnotSwap {
		lpUgnot += sentUgnot        // update LP value
		amtOut := lpPtn - k/lpUgnot // amt is in ptn
		lpPtn -= amtOut

		coinOut := std.NewCoin(ptn.ExternalPtnDenom, amtOut)
		coinsOut := std.NewCoins(coinOut)
		bank.SendCoins(this.Addr(), caller, coinsOut)

		return coinOut
	}

	// Swapping ptn for ugnot
	if ptnSwap {
		lpPtn += sentPtn            // update LP value
		amtOut := lpUgnot - k/lpPtn // amt is in ugnot
		lpUgnot -= amtOut

		coinOut := std.NewCoin("ugnot", amtOut)
		coinsOut := std.NewCoins(coinOut)
		bank.SendCoins(this.Addr(), caller, coinsOut)

		return coinOut
	}

	panic("could not execute swap properly")
}

func Render(_ string) string {
	out := ufmt.Sprintf("Current state of the liquidity pool:\n\n - ugnot: %d\n\n - ptn: %d\n\n", lpUgnot, lpPtn)

	return out
}
