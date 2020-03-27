function ortho_BlochWavefunc!( psiks )
    for i = 1:length(psiks)
        ortho_sqrt!(psiks[i])
    end
end

"""
Return total energies
"""
function calc_energies_grad!( Ham, psiks, g, Kg )

    Rhoe = calc_rhoe( Ham, psiks )
    update!( Ham, Rhoe )
    
    Ham.energies = calc_energies( Ham, psiks )

    Nspin = Ham.electrons.Nspin
    Nkpt = Ham.pw.gvecw.kpoints.Nkpt

    for ispin = 1:Nspin, ik = 1:Nkpt
        Ham.ispin = ispin
        Ham.ik = ik
        i = ik + (ispin-1)*Nkpt
        calc_grad!( Ham, psiks[i], g[i] )
        Kprec!( ik, Ham.pw, g[i], Kg[i] )
    end

    return sum( Ham.energies )
end


# Modify Ham and psiks
function calc_energies_only!( Ham, psiks )
    Rhoe = calc_rhoe( Ham, psiks )
    update!( Ham, Rhoe )
    Ham.energies = calc_energies( Ham, psiks )
    return sum( Ham.energies )
end


# Wrapper for calc_grad! for BlochWavefunc
function calc_grad!( Ham::Hamiltonian, psiks::BlochWavefunc, g::BlochWavefunc )
    #
    Rhoe = calc_rhoe( Ham, psiks )
    update!( Ham, Rhoe )
    #
    Nspin = Ham.electrons.Nspin
    Nkpt = Ham.pw.gvecw.kpoints.Nkpt
    #
    for ispin in 1:Nspin, ik in 1:Nkpt
        Ham.ispin = ispin
        Ham.ik = ik
        i = ik + (ispin-1)*Nkpt
        calc_grad!( Ham, psiks[i], g[i] )
    end
    return
end

function calc_grad!( Ham::Hamiltonian, ψ::Array{ComplexF64,2}, g::Array{ComplexF64,2} )

    ik = Ham.ik
    ispin = Ham.ispin

    Nstates = size(ψ,2)
    Nkpt = Ham.pw.gvecw.kpoints.Nkpt
    ikspin = ik + (ispin - 1)*Nkpt
    Focc = Ham.electrons.Focc

    Hψ = op_H( Ham, ψ )
    Hsub = ψ' * Hψ
    Hψ = Hψ - ψ*Hsub
    for ist in 1:Nstates
        g[:,ist] = Focc[ist,ikspin] * Hψ[:,ist]
    end
    return

end

function Kprec!( ik::Int64, pw::PWGrid, psi, Kpsi )

    Ngw_ik  = size(psi)[1]
    Nstates = size(psi)[2]
    idx_gw2g = pw.gvecw.idx_gw2g[ik]
    G = pw.gvec.G
    k = pw.gvecw.kpoints.k[:,ik]

    for ist = 1:Nstates
        for igk = 1:Ngw_ik
            ig = idx_gw2g[igk]
            Gw2 = (G[1,ig] + k[1])^2 + (G[2,ig] + k[2])^2 + (G[3,ig] + k[3])^2
            Kpsi[igk,ist] = psi[igk,ist] / ( 1.0 + Gw2 )
        end
    end
    return
end

function do_step!( psiks, α, d )
    for i in 1:length(psiks)
        psiks[i] = psiks[i] + α*d[i]
        ortho_sqrt!( psiks[i] )
    end
    return
end