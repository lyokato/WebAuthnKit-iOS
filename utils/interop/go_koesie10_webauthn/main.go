package main

import (
	"crypto/x509"
	"encoding/base64"
	"fmt"

	"github.com/koesie10/webauthn/protocol"
)

func main() {

	rpId := "https://example.org"
	rpOrigin := "https://example.org"

	assertionChallenge, err := base64.RawURLEncoding.DecodeString("rtnHiVQ7")
	if err != nil {
		fmt.Printf("Challenge Format Error: %v", err)
		return
	}

	b64Id := "uRH__GRxQYe_Q5cCSlgYug"
	rawId, err := base64.RawURLEncoding.DecodeString("uRH__GRxQYe_Q5cCSlgYug")
	if err != nil {
		fmt.Printf("ID Format Error: %v", err)
		return
	}

	attsClientData, err := base64.RawURLEncoding.DecodeString("eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIiwiY2hhbGxlbmdlIjoicnRuSGlWUTciLCJvcmlnaW4iOiJodHRwczpcL1wvZXhhbXBsZS5vcmcifQ")
	if err != nil {
		fmt.Printf("ClientData Format Error: %v", err)
		return
	}

	attsObj, err := base64.RawURLEncoding.DecodeString("o2hhdXRoRGF0YViUUNepBeMEa4hjg2LMNKMaGuU0dmylXjqjl5Ue_mU7BitBAAAAAAAAAAAAAAAAAAAAAAAAAAAAELkR__xkcUGHv0OXAkpYGLqlAQIDJiABIVggcveTEqCmGOGZz_4cFwd3HoBdzk4IF7E0xEpLHk0aBN8iWCC_fRoVhaVW1r_73coq6pR1Eybvp7o2w8puhRtejsut82NmbXRmcGFja2VkZ2F0dFN0bXSiY2FsZyZjc2lnWEYwRAIgbrC6c2l6VcttVxNLeOd3q-Og4nlnTMxo33TrnoX2ki8CIDgFh5YlhPSEw-h2joSrfD4eiBYplFw_izUI2iQryqcu")
	if err != nil {
		fmt.Printf("Attestation Format Error: %v", err)
		return
	}

	assertionClientData, err := base64.RawURLEncoding.DecodeString("eyJ0eXBlIjoid2ViYXV0aG4uZ2V0IiwiY2hhbGxlbmdlIjoicnRuSGlWUTciLCJvcmlnaW4iOiJodHRwczpcL1wvZXhhbXBsZS5vcmcifQ")
	if err != nil {
		fmt.Printf("ClientData Format Error: %v", err)
		return
	}

	authData, err := base64.RawURLEncoding.DecodeString("UNepBeMEa4hjg2LMNKMaGuU0dmylXjqjl5Ue_mU7BisBAAAAAQ")
	if err != nil {
		fmt.Printf("AuthData Format Error: %v", err)
		return
	}
	signature, err := base64.RawURLEncoding.DecodeString("MEUCIQDHv3C_QjqX_0UerM3sB0NbusD5RMp3QpK5OqGyk-6U-wIgBLEGrtF64i3N2S6q9x_JRLjCcAguwjoZ_SbCp2g2F08")
	if err != nil {
		fmt.Printf("Signature Format Error: %v", err)
		return
	}
	userHandle, err := base64.RawURLEncoding.DecodeString("bHlva2F0bw")
	if err != nil {
		fmt.Printf("UserHandle Format Error: %v", err)
		return
	}

	attsRes := protocol.AttestationResponse{
		PublicKeyCredential: protocol.PublicKeyCredential{
			ID:    b64Id,
			RawID: rawId,
			Type:  "public-key",
		},
		Response: protocol.AuthenticatorAttestationResponse{
			AuthenticatorResponse: protocol.AuthenticatorResponse{
				ClientDataJSON: attsClientData,
			},
			AttestationObject: attsObj,
		},
	}

	fmt.Println("Parse Attestation Response")
	atts, err := protocol.ParseAttestationResponse(attsRes)
	if err != nil {
		e := protocol.ToWebAuthnError(err)
		fmt.Printf("Error: %s, %s, %s", e.Name, e.Debug, e.Hint)
		return
	}

	/* This returns err, because this webauthn library doesn't support self-attestation
	validAtts, err := protocol.IsValidAttestation(atts, assertionChallenge, rpId, rpOrigin)
	if err != nil {
		e := protocol.ToWebAuthnError(err)
		fmt.Printf("Error: %s, %s, %s", e.Name, e.Debug, e.Hint)
		return
	}
	if !validAtts {
		fmt.Println("Invalid Attestation!")
		return
	}
	*/

	pubKey := atts.Response.Attestation.AuthData.AttestedCredentialData.COSEKey

	cert := &x509.Certificate{
		PublicKey: pubKey,
	}

	assertionRes := protocol.AssertionResponse{
		PublicKeyCredential: protocol.PublicKeyCredential{
			ID:    b64Id,
			RawID: rawId,
			Type:  "public-key",
		},
		Response: protocol.AuthenticatorAssertionResponse{
			AuthenticatorResponse: protocol.AuthenticatorResponse{
				ClientDataJSON: assertionClientData,
			},
			AuthenticatorData: authData,
			Signature:         signature,
			UserHandle:        userHandle,
		},
	}
	assertion, err := protocol.ParseAssertionResponse(assertionRes)
	if err != nil {
		e := protocol.ToWebAuthnError(err)
		fmt.Printf("Error: %s, %s, %s", e.Name, e.Debug, e.Hint)
		return
	}

	valid, err := protocol.IsValidAssertion(assertion, assertionChallenge, rpId, rpOrigin, cert)
	if err != nil {
		e := protocol.ToWebAuthnError(err)
		fmt.Printf("Error: %s, %s, %s", e.Name, e.Debug, e.Hint)
		return
	}

	if !valid {
		fmt.Println("Invalid Assertion!")
		return
	}

	fmt.Println("Valid Assertion!!!")

}
