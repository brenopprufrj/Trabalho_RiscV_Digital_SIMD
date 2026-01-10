# Programa de teste vetorial
vaddi v1, v0, 5    # v1 = v0 + 5 = [5, 5, 5, 5]
vaddi v2, v0, 3    # v2 = v0 + 3 = [3, 3, 3, 3]
vadd  v3, v1, v2   # v3 = v1 + v2 = [8, 8, 8, 8]
vsub  v4, v1, v2   # v4 = v1 - v2 = [2, 2, 2, 2]
vslli v5, v1, 2    # v5 = v1 << 2 = [20, 20, 20, 20]
nop                # fim
