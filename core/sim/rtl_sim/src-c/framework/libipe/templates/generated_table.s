    .global ecall_table
    .global max_ecall_index
    .sect ".ipe_const"
    .align 2

    ; table to register address and number of registers used as argument for every entry function
    ; table consulted at runtime by "ipe_entry" stub in ipe_stubs.s
ecall_table:
{% for entry in entry_functions %}
    .global {{ entry.internal_name }}
    .word {{ entry.internal_name }}
    .word {{ entry.bitmap }}
{% endfor %}

max_ecall_index:
    .word {{ max_entry_index }}
