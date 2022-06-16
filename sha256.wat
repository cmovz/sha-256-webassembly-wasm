;; 2022 Douglas Maieski - https://github.com/cmovz
(module
  (memory (export "memory") 1)
  (export "SHA256" (func $SHA256))

  ;; sha-256 round constants
  (data (i32.const 0) "\98\2f\8a\42\91\44\37\71\cf\fb\c0\b5\a5\db\b5\e9\5b"
    "\c2\56\39\f1\11\f1\59\a4\82\3f\92\d5\5e\1c\ab\98\aa\07\d8\01\5b\83\12"
    "\be\85\31\24\c3\7d\0c\55\74\5d\be\72\fe\b1\de\80\a7\06\dc\9b\74\f1\9b"
    "\c1\c1\69\9b\e4\86\47\be\ef\c6\9d\c1\0f\cc\a1\0c\24\6f\2c\e9\2d\aa\84"
    "\74\4a\dc\a9\b0\5c\da\88\f9\76\52\51\3e\98\6d\c6\31\a8\c8\27\03\b0\c7"
    "\7f\59\bf\f3\0b\e0\c6\47\91\a7\d5\51\63\ca\06\67\29\29\14\85\0a\b7\27"
    "\38\21\1b\2e\fc\6d\2c\4d\13\0d\38\53\54\73\0a\65\bb\0a\6a\76\2e\c9\c2"
    "\81\85\2c\72\92\a1\e8\bf\a2\4b\66\1a\a8\70\8b\4b\c2\a3\51\6c\c7\19\e8"
    "\92\d1\24\06\99\d6\85\35\0e\f4\70\a0\6a\10\16\c1\a4\19\08\6c\37\1e\4c"
    "\77\48\27\b5\bc\b0\34\b3\0c\1c\39\4a\aa\d8\4e\4f\ca\9c\5b\f3\6f\2e\68"
    "\ee\82\8f\74\6f\63\a5\78\14\78\c8\84\08\02\c7\8c\fa\ff\be\90\eb\6c\50"
    "\a4\f7\a3\f9\be\f2\78\71\c6"
  )

  (func $ConvertEndianness_i32 (param $x i32) (result i32) (local $temp i32)
    ;; byte 0
    local.get $x
    i32.const 0xff
    i32.and
    i32.const 24
    i32.shl
    local.set $temp

    ;; byte 1
    local.get $x
    i32.const 0xff00
    i32.and
    i32.const 8
    i32.shl
    local.get $temp
    i32.or
    local.set $temp

    ;; byte 2
    local.get $x
    i32.const 0xff0000
    i32.and
    i32.const 8
    i32.shr_u
    local.get $temp
    i32.or
    local.set $temp

    ;; byte 3
    local.get $x
    i32.const 0xff000000
    i32.and
    i32.const 24
    i32.shr_u
    local.get $temp
    i32.or
  )

  (func $ConvertEndianness_i64 (param $x i64) (result i64) (local $var0 i64)
    ;; byte 0
    local.get $x
    i64.const 0xff
    i64.and
    i64.const 56
    i64.shl
    local.set $var0

    ;; byte 1
    local.get $x
    i64.const 0xff00
    i64.and
    i64.const 40
    i64.shl
    local.get $var0
    i64.or
    local.set $var0

    ;; byte 2
    local.get $x
    i64.const 0xff0000
    i64.and
    i64.const 24
    i64.shl
    local.get $var0
    i64.or
    local.set $var0

    ;; byte 3
    local.get $x
    i64.const 0xff000000
    i64.and
    i64.const 8
    i64.shl
    local.get $var0
    i64.or
    local.set $var0

    ;; byte 4
    local.get $x
    i64.const 0xff000000
    i64.and
    i64.const 8
    i64.shr_u
    local.get $var0
    i64.or
    local.set $var0

    ;; byte 5
    local.get $x
    i64.const 0xff00000000
    i64.and
    i64.const 24
    i64.shr_u
    local.get $var0
    i64.or
    local.set $var0

    ;; byte 6
    local.get $x
    i64.const 0xff0000000000
    i64.and
    i64.const 40
    i64.shr_u
    local.get $var0
    i64.or
    local.set $var0

    ;; byte 7
    local.get $x
    i64.const 0xff000000000000
    i64.and
    i64.const 56
    i64.shr_u
    local.get $var0
    i64.or
  )

  (func $SHA256Compress (param $block i32)
    (local $i i32) (local $pos i32) (local $var0 i32) (local $var1 i32)
    (local $a i32) (local $b i32) (local $c i32) (local $d i32)
    (local $e i32) (local $f i32) (local $g i32) (local $h i32)

    i32.const 0
    local.tee $i
    local.set $pos
    loop $copy_loop
      ;; load i32 from source
      local.get $block
      local.get $pos
      i32.add
      i32.load
      call $ConvertEndianness_i32
      local.set $var0

      ;; store in ctx->w
      i32.const 288
      local.get $pos
      i32.add
      local.get $var0
      i32.store

      ;; pos += 4
      local.get $pos
      i32.const 4
      i32.add
      local.set $pos

      ;; ++i != 64
      local.get $i
      i32.const 1
      i32.add
      local.tee $i
      i32.const 64
      i32.ne
      br_if $copy_loop
    end

    i32.const 16
    local.set $i
    i32.const 64
    local.set $pos
    loop $expansion_loop
      ;; c->w[i-16]
      i32.const 224
      local.get $pos
      i32.add
      i32.load

      ;; s0
      ;; ROR(c->w[i-15],7)
      i32.const 228
      local.get $pos
      i32.add
      i32.load
      local.tee $var0
      i32.const 7
      i32.rotr
      ;; ROR(c->w[i-15],18)
      local.get $var0
      i32.const 18
      i32.rotr
      ;; c->w[i-15] >> 3
      local.get $var0
      i32.const 3
      i32.shr_u
      ;; xor them
      i32.xor
      i32.xor
      i32.add

      ;; s1
      ;; c->w[i-2]
      i32.const 280
      local.get $pos 
      i32.add
      i32.load 
      ;; ROR(c->w[i-2],17)
      local.tee $var0
      i32.const 17
      i32.rotr
      ;; ROR(c->w[i-2],19)
      local.get $var0
      i32.const 19
      i32.rotr
      ;; c->w[i-2] >> 10
      local.get $var0
      i32.const 10
      i32.shr_u
      i32.xor
      i32.xor
      i32.add

      ;; c->w[i-7]
      i32.const 260
      local.get $pos 
      i32.add
      i32.load 
      i32.add

      local.set $var0
      
      ;; get w position
      i32.const 288
      local.get $pos
      i32.add
      local.get $var0
      i32.store

      ;; pos += 4
      local.get $pos
      i32.const 4
      i32.add
      local.set $pos
      
      ;; ++i != 64
      local.get $i
      i32.const 1
      i32.add
      local.tee $i
      i32.const 64
      i32.ne
      br_if $expansion_loop
    end

    i32.const 256
    i32.load
    local.set $a
    i32.const 260
    i32.load
    local.set $b
    i32.const 264
    i32.load
    local.set $c
    i32.const 268
    i32.load
    local.set $d
    i32.const 272
    i32.load
    local.set $e
    i32.const 276
    i32.load
    local.set $f
    i32.const 280
    i32.load
    local.set $g
    i32.const 284
    i32.load
    local.set $h

    i32.const 0
    local.tee $i
    local.set $pos
    loop $main_loop
      ;; c->h
      local.get $h

      ;; S1(c->e)
      local.get $e
      i32.const 6
      i32.rotr
      local.get $e
      i32.const 11
      i32.rotr
      local.get $e
      i32.const 25
      i32.rotr 
      i32.xor
      i32.xor
      i32.add

      ;; CH(c->e, c->f, c->g)
      local.get $e
      local.get $f
      i32.and
      local.get $e
      i32.const 0xffffffff
      i32.xor
      local.get $g
      i32.and
      i32.xor
      i32.add

      ;; k[i]
      local.get $pos
      i32.load
      i32.add

      ;; c->w[i]
      i32.const 288
      local.get $pos
      i32.add
      i32.load
      i32.add

      ;; temp1
      local.set $var0

      ;; S0(c->a)
      local.get $a
      i32.const 2
      i32.rotr
      local.get $a
      i32.const 13
      i32.rotr
      local.get $a
      i32.const 22
      i32.rotr
      i32.xor
      i32.xor

      ;; MAJ(c->a, c->b, c->c)
      local.get $a
      local.get $b
      i32.and
      local.get $a
      local.get $c
      i32.and
      local.get $b
      local.get $c
      i32.and
      i32.xor
      i32.xor

      ;; temp2 is on the stack
      i32.add

      local.get $g
      local.set $h
      local.get $f
      local.set $g
      local.get $e
      local.set $f
      local.get $d
      local.get $var0
      i32.add
      local.set $e
      local.get $c
      local.set $d
      local.get $b
      local.set $c
      local.get $a
      local.set $b
      local.get $var0
      i32.add
      local.set $a

      ;; pos += 4
      local.get $pos
      i32.const 4
      i32.add
      local.set $pos
      
      ;; ++i != 64
      local.get $i
      i32.const 1
      i32.add
      local.tee $i
      i32.const 64
      i32.ne
      br_if $main_loop
    end

    i32.const 256
    i32.load
    local.get $a
    i32.add
    local.set $var0
    i32.const 256
    local.get $var0
    i32.store 

    i32.const 260
    i32.load
    local.get $b
    i32.add
    local.set $var0
    i32.const 260
    local.get $var0
    i32.store 

    i32.const 264
    i32.load
    local.get $c
    i32.add
    local.set $var0
    i32.const 264
    local.get $var0
    i32.store 

    i32.const 268
    i32.load
    local.get $d
    i32.add
    local.set $var0
    i32.const 268
    local.get $var0
    i32.store 

    i32.const 272
    i32.load
    local.get $e
    i32.add
    local.set $var0
    i32.const 272
    local.get $var0
    i32.store 

    i32.const 276
    i32.load
    local.get $f
    i32.add
    local.set $var0
    i32.const 276
    local.get $var0
    i32.store 

    i32.const 280
    i32.load
    local.get $g
    i32.add
    local.set $var0
    i32.const 280
    local.get $var0
    i32.store 

    i32.const 284
    i32.load
    local.get $h
    i32.add
    local.set $var0
    i32.const 284
    local.get $var0
    i32.store 
  )

  (func $SHA256 (param $data i32) (param $size i32) (param $dest i32)
    (local $i i32) (local $pos i32) (local $var0 i32) 
    ;; init h0 to h7
    i32.const 256
    i32.const 0x6a09e667
    i32.store
    i32.const 260
    i32.const 0xbb67ae85
    i32.store
    i32.const 264
    i32.const 0x3c6ef372
    i32.store
    i32.const 268
    i32.const 0xa54ff53a
    i32.store
    i32.const 272
    i32.const 0x510e527f
    i32.store
    i32.const 276
    i32.const 0x9b05688c
    i32.store
    i32.const 280
    i32.const 0x1f83d9ab
    i32.store
    i32.const 284
    i32.const 0x5be0cd19
    i32.store
    
    ;; consume all the possible data from the buffer
    ;; size / 64
    local.get $size
    i32.const 6
    i32.shr_u
    local.set $i
    block $exit_compression_loop
      loop $compression_loop
        ;; check i-- != 0 and
        local.get $i
        i32.eqz
        br_if $exit_compression_loop
        local.get $i
        i32.const 1
        i32.sub
        local.set $i

        ;; compress
        local.get $data
        call $SHA256Compress

        ;; update data position
        local.get $data
        i32.const 64
        i32.add
        local.set $data

        br $compression_loop
      end
    end

    ;; size % 64
    local.get $size
    i32.const 0x3f
    i32.and
    local.set $pos

    ;; copy data to buffer
    i32.const 544
    local.get $data
    local.get $pos
    memory.copy

    ;; append bits 10000000
    i32.const 544
    local.get $pos
    i32.add
    i32.const 0x80
    i32.store8
    local.get $pos
    i32.const 1
    i32.add
    local.tee $pos

    ;; check if pos <= 56
    i32.const 56
    i32.le_u
    if
      ;; handle single block
      ;; append 0 bits
      i32.const 544
      local.get $pos
      i32.add
      local.set $i
      i32.const 600 ;; last 64 bits are for the size
      local.get $i
      i32.sub
      local.set $var0
      local.get $i
      i32.const 0x00
      local.get $var0
      memory.fill

      ;; where to store the size
      i32.const 600

      ;; append size
      local.get $size
      i64.extend_i32_u
      i64.const 3
      i64.shl
      call $ConvertEndianness_i64
      i64.store

      ;; compress
      i32.const 544
      call $SHA256Compress
    else
      ;; handle 2 blocks
      ;; append 0 bits
      i32.const 544
      local.get $pos
      i32.add
      local.set $i
      i32.const 608 ;; size is on the next block
      local.get $i
      i32.sub
      local.set $var0
      local.get $i
      i32.const 0x00
      local.get $var0
      memory.fill

      ;; compress first block
      i32.const 544
      call $SHA256Compress

      ;; fill second block with 0s
      i32.const 544
      i32.const 0x00
      i32.const 64
      memory.fill

      ;; append size
      ;; where to store the size
      i32.const 600

      ;; append size
      local.get $size
      i64.extend_i32_u
      i64.const 3
      i64.shl
      call $ConvertEndianness_i64
      i64.store

      ;; compress second block
      i32.const 544
      call $SHA256Compress
    end

    i32.const 0
    local.tee $i
    local.set $pos
    loop $copy_loop
      i32.const 256
      local.get $pos
      i32.add
      i32.load
      call $ConvertEndianness_i32
      local.set $var0

      local.get $dest
      local.get $pos
      i32.add
      local.get $var0
      i32.store

      ;; pos += 4
      local.get $pos
      i32.const 4
      i32.add
      local.set $pos
      
      ;; ++i != 8
      local.get $i
      i32.const 1
      i32.add
      local.tee $i
      i32.const 8
      i32.ne
      br_if $copy_loop
    end

  )
)