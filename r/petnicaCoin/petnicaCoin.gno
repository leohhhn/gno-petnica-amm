package coin

import (
	"std"
)

const (
	denom           = "ptn"
	maxFaucetAmount = 100
)

var (
	roBank           std.Banker
	issueBank        std.Banker
	this             std.Realm
	ExternalPtnDenom = "/" + std.CurrentRealm().PkgPath() + ":" + denom // to be reconsidered in gno
)

func init() {
	roBank = std.GetBanker(std.BankerTypeReadonly)
	issueBank = std.GetBanker(std.BankerTypeRealmIssue)
	this = std.CurrentRealm()

	// Mint some $ptn to this realm
	issueBank.IssueCoin(this.Addr(), denom, 1_000_000)
}

func Faucet(amt int64) {
	if amt < 0 || amt > maxFaucetAmount {
		panic("faucet amount must be between 0 and 100")
	}

	caller := std.PrevRealm().Addr()
	issueBank.IssueCoin(caller, denom, amt)
}

func Render(_ string) string {
	balance := roBank.GetCoins(this.Addr())

	return balance.String()
}
