(import :std/foreign-test-support
        :std/test
        (only-in :gerbil/gambit foreign-tags))

(export foreign-test)

(define foreign-test
  (test-suite "test :std/foreign"
              (def test-str1 "hello")
              (def test-str2 "world")

              (define (make-abc a b)
                (let (o (malloc-abc))
                  (abc-a-set! o a)
                  (abc-b-set! o b)
                  o))

              (test-case "c struct"
                         (def obj (malloc-abc))

                         (abc-a-set! obj test-str1)
                         (abc-b-set! obj test-str2)

                         (check (abc-a obj) => test-str1)
                         (check (abc-b obj) => test-str2)

                         (check (abc-ptr? obj) => '(abc*)))

              (test-case "c struct compatible-tags"
                         (def in-struct (malloc-a_struct))
                         (check (member 'an_alias* (foreign-tags in-struct)) => '(an_alias*))
                         (a_struct-g-set! in-struct 99)

                         (def out-alias (in-struct-out-alias in-struct))
                         (check (a_struct-ptr? out-alias) => '(a_struct*))
                         (check (a_struct-g out-alias) => (a_struct-g in-struct))
                         (check (a_struct-h out-alias) => 77)

                         (def out-struct (in-alias-out-struct out-alias))
                         (check (a_struct-g out-struct) => (a_struct-h out-alias))
                         (check (a_struct-h out-struct) => (a_struct-g in-struct)))

              (test-case "c struct as-typedef"
                         (def obj (malloc-anon_struct))

                         (anon_struct-a-set! obj test-str1)
                         (anon_struct-b-set! obj test-str2)

                         (check (anon_struct-a obj) => test-str1)
                         (check (anon_struct-b obj) => test-str2)

                         (check (anon_struct-ptr? obj) => '(anon_struct*)))

              (test-case "c struct array"

                         (def obj-array (malloc-abc-array 2))

                         (def obj1 (malloc-abc))
                         (abc-a-set! obj1 test-str1)

                         (def obj2 (malloc-abc))
                         (abc-a-set! obj2 test-str2)

                         (abc-array-set! obj-array 0 obj1)
                         (abc-array-set! obj-array 1 obj2)

                         (check (abc-a (abc-array-ref obj-array 0)) => test-str1)
                         (check (abc-a (abc-array-ref obj-array 1)) => test-str2))

              (test-case "c int struct array"
                         (define y (malloc-bar))
                         (bar-i-set! y 123)
                         (bar-j-set! y 456)

                         (define y2 (malloc-bar))
                         (bar-i-set! y2 320)
                         (bar-j-set! y2 328)

                         (define k (malloc-bar-array 2))
                         (bar-array-set! k 0 y)
                         (bar-array-set! k 1 y2)

                         (check (bar-i (bar-array-ref k 1)) => 320))

              (test-case "modifying c strings"
                         (def obj1 (malloc-abc))

                         (def t3 (string-append test-str1 test-str2))
                         (def t4 (string-append test-str1 " test"))

                         (abc-a-set! obj1 test-str1)
                         (abc-b-set! obj1 test-str2)
                         (abc-a-set! obj1 t3)
                         (abc-b-set! obj1 t4)

                         (check (abc-a obj1) => t3)
                         (check (abc-b obj1) => t4))

              (test-case "nested structs"
                         (def foo-arr (malloc-foo-array 2))

                         (def obj1 (make-abc test-str1 test-str2))
                         (def obj2 (make-abc test-str2 test-str1))

                         (def t5 "here we go")
                         (def t6 "but not")

                         (def foo1 (malloc-foo))
                         (foo-a1-set! foo1 obj1)
                         (foo-d2-set! foo1 obj2)
                         (foo-str-set! foo1 t5)

                         (def foo2 (malloc-foo))
                         (foo-a1-set! foo2 obj2)
                         (foo-d2-set! foo2 obj1)
                         (foo-str-set! foo2 t6)

                         (foo-array-set! foo-arr 0 foo1)
                         (foo-array-set! foo-arr 1 foo2)

                         (check (foo-str (foo-array-ref foo-arr 0)) => t5)
                         (check (foo-str (foo-array-ref foo-arr 1)) => t6))))