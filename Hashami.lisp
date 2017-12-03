(setq dimension 0)
(setq states nil)
(setq states-vertical nil)

(defun start()
  (format t "~% Izaberite mod igre [mod]..")
  (format t "~% [1] Covek-racunar :: x o")
  (format t "~% [2] Racunar-covek :: x o")
  (format t "~% [3] Covek-covek :: x o")
  (format t "~% [exit] Izlaz ~%")
  
  (let 
   ((mode (read)))
    (cond
     ((equalp mode 1)
      (progn 
        (form-matrix)
        (print-matrix (states-to-matrix 1 dimension states))
        (make-move t))
     )
     ((equalp mode 2) nil)
     ((equalp mode 3) 
      (progn 
         (form-matrix)
         (print-matrix (states-to-matrix 1 dimension states))
         (make-move t)
      ))
     ((string-equal mode "exit") #+sbcl (sb-ext:quit))
     (t (format t "~% Nepravilan mod ~%~%") (start))
)))

(defun form-matrix ()
  (format t "~% Unesite dimenziju table za Hashami igru, dimenzija treba da bude u opsegu 9-11~%")
  (setq dimension (read))
  (cond
   ((< dimension 9) (format t "~% Dimenzija table je premala") (form-matrix))
   ((> dimension 11) (format t "~% Dimenzija table je prevelika") (form-matrix))
   (t (progn (setq states-vertical (initial-states-vertical dimension)) (setq states (initial-states dimension))))
  )
)

(defun make-move (xo)  ; xo true : x | false: o za zaizmenicne poteze
  (format t "~%~%~A: unesite potez oblika ((x y) (n m)): " (if xo #\x #\o))
  (progn
  (let* ((input (read)) 
         (current (form-move (car input))) 
         (move (form-move (cadr input))) 
         (player (if xo #\x #\o))
         (horizontal-coded (states-to-matrix 1 dimension states))
         (vertical-coded (states-to-matrix 1 dimension states-vertical))
         ; matrice kodiranja koje mogu da se pre povlacenja poteza prolsedjuju (validate-move ..)
         )
    (cond
     ((string-equal (caar input) "exit") #+sbcl (sb-ext:quit))
     ((or (null current) (null move) (> (car current) dimension) (> (cadr current) dimension) (> (car move) dimension) (> (cadr move) dimension)) (format t "~%~%Nepravilan format ili granice polja..~%") (make-move xo)) ; nepravilno formatiran unos poteza rezultuje ponovnim unosom istog poteza
     (t (progn 
          (change-state (car current) (cadr current) (car move) (cadr move) xo)
          (print-matrix (states-to-matrix 1 dimension states))
          (make-move (not xo))
    ))
    )
)))

(defun form-move (move)
  (if (and (member (car move) '(A B C D E F G H I J K)) (member (cadr move) '(1 2 3 4 5 6 7 8 9 10 11)))
      (cond 
       ((equal (car move) 'a) (list '1 (cadr move)))
       ((equal (car move) 'b) (list '2 (cadr move)))
       ((equal (car move) 'c) (list '3 (cadr move)))
       ((equal (car move) 'd) (list '4 (cadr move)))
       ((equal (car move) 'e) (list '5 (cadr move)))
       ((equal (car move) 'f) (list '6 (cadr move)))
       ((equal (car move) 'g) (list '7 (cadr move)))
       ((equal (car move) 'h) (list '8 (cadr move)))
       ((equal (car move) 'i) (list '9 (cadr move)))
       ((equal (car move) 'j) (list '10 (cadr move)))
       ((equal (car move) 'k) (list '11 (cadr move)))
       (t '())
      )
    '()
))

(defun left-right (horizontal-state value)
  (cond
   ((null horizontal-state) nil)
   ((and (listp (second horizontal-state)) (equalp (car (second horizontal-state)) value)) (list (car horizontal-state) (third horizontal-state)))
   (t (left-right (cdr horizontal-state) value))
  )
)

(defun validate-move (x y new-x new-y horizontal vertical xo)
  (cond
   ((and xo (member-if-not (list x y) (car states))) nil)
   ((and (not xo) (member-if-not (list x y) (cadr states))) nil)
   ; podeljeno validate-vertical/validate-horizontal
   ((equalp x new-x) ())
   ((equalp y new-y) ())
  )
)

(defun insert-state (x y rearanged-states)
  (cond
   ((null rearanged-states) (list (list x y)))
   ((or (and (equalp (caar rearanged-states) x) (< y (cadar rearanged-states))) (< x (caar rearanged-states))) (cons (list x y) rearanged-states))
   (t (cons (car rearanged-states) (insert-state x y (cdr rearanged-states))))
  )
)

(defun remove-state (x y changed-states)
  (cond
   ((null changed-states) nil)
   ((and (equalp (caar changed-states) x) (equalp y (cadar changed-states))) (cdr changed-states))
   (t (cons (car changed-states) (remove-state x y (cdr changed-states))))
  )
)

(defun change-state (x y x-new y-new xo)
  (cond
   (xo (progn 
         (setq states-vertical (list (insert-state y-new x-new (remove-state y x (car states-vertical))) (cadr states-vertical)))
         (setq states (list (insert-state x-new y-new (remove-state x y (car states))) (cadr states)))
         ))
   ((not xo) (progn
         (setq states-vertical (list (car states-vertical) (insert-state y-new x-new (remove-state y x (cadr states-vertical)))))
         (setq states (list (car states) (insert-state x-new y-new (remove-state x y (cadr states)))))      
         ))
  )
)
;funkcija za generisanje poteza u jednom redu, ulazni parametri - lvl (koji red evaluiramo), seclst (predzadnji element), lst (prethodni element), xo (kog igrača evaluiramo), row - (kodirani red), res (rezultat), izlaz - lista sa u formatu (((trenutna figura - koordinate)((moguca nova pozicija 1) (moguca nova pozicija 2)...))(...))
(defun generate-moves-for-row (lvl seclst lst xo row res)

  (let* ((value (encode-element (car row) xo)))
    (cond
      ((and (null seclst) (null lst)) (generate-moves-for-row lvl lst value xo (cdr row) res))
      ((null row) res)
;      ((zerop value) (generate-moves-for-row lvl lst 0 xo (cdr row) res ))
      ((atom value) (cond
                      ((zerop value) (generate-moves-for-row lvl lst 0 xo (cdr row) res ))
                      ((listp lst) (generate-moves-for-row lvl lst value xo (cdr row) (append res (append-moves-for-row lvl lst value NIL))))
                      ((zerop lst)(cond
                                    ((and (not(null seclst)) (listp seclst))(generate-moves-for-row lvl lst value xo (cdr row) (append res (append-moves-for-row lvl seclst 0 T))))
                                    (t (generate-moves-for-row lvl lst value xo (cdr row) res))))
                      ))
      ((and(atom lst) (not (zerop lst))) (generate-moves-for-row lvl lst value xo (cdr row) (append res (append-moves-for-row lvl value lst T))))
       (t (generate-moves-for-row lvl lst value xo (cdr row) res))
       )
    )
  )

;pomoćna funkcija za generate-moves for row, ulazni parametri - el (element koji ispitujemo), xo (kog igrača evaluiramo), izlaz - ako je element koordinata igrača koji nas interesuje onda vraćamo tu koordinatu, ako je od protivnika - vraćamo nulu, ako je broj slobodnih mesta - vraćamo ga takvog kakav je
(defun encode-element (el xo)

  (cond
    ((listp el)(cond
                 ((equalp (cadr el) xo) el)
                 (t 0)))
    (t el)
    )
  )

(defun append-moves-for-row (lvl el size prev)
    (list(cons (list lvl (car el)) (list (cond
                                        ((zerop size) (list lvl (+ (car el) 2)))
                                        (t (loop for x from 1 to size collect (list lvl (cond
                                                                                          ((null prev)(+ (car el) x))
                                                                                          (t (- (car el) x))))))))))
  )

(defun initial-row (row column) 
  (cond
    ((zerop row) nil)
    (t (append (initial-row (- row 1) column) (list (list column row))))
    )
)

;;funkcija koja defnise inicijalno stanje table u formi
;;((lista figura prvog igraca) (lista figura drugog igraca))
(defun initial-states (dim)
  (list (append (initial-row dim 1) (initial-row dim 2)) (append (initial-row dim (- dim 1)) (initial-row dim dim)) )
)

(defun initial-states-vertical (dim)
  (list (initial-column dim) (initial-column-extend dim))
)

(defun initial-column (dim)
  (cond
   ((zerop dim) nil)
   (t (append (initial-column (- dim 1)) (list (list dim 1) (list dim 2))))
  )
)

(defun initial-column-extend (dim)
  (cond
   ((zerop dim) nil)
   (t (append (initial-column-extend (- dim 1)) (List (list dim (- dimension 1)) (list dim dimension))))
  )
)

(defun show-initial-matrix (dim)
  (print-matrix(states-to-matrix 1 dim  (initial-states dim)))
)

(defun print-matrix (mat)
  (cond
    ((null mat) NIL)
    (t (print-row (car mat)) (print-matrix (cdr mat)))
    )
)

; (setq matrix (initial-states 10))
; (print-matrix(states-to-matrix 1 10 matrix))


;; funkcija za stampanje reda matrice, prosledjenog u formi liste atoma, gde
;; pozitivna vrednost oznacava prazna polja a sama velicina vrednosti
;; broj uzastopnih blanko polja, negativna vrednost oznacava "o", a nula "x"
(defun print-row (row)
  (cond
    ((null row) (fresh-line))
    ((atom (car row)) (print-blank (car row)) (print-row (cdr row)) )
   ;; ((zerop (car row)) (format t "x ") (print-row (cdr row)))
    (t (format t " ~a " (cadar row)) (print-row (cdr row)))
    )
)

;; Pomocna funkcija za stampanje reda,koristi se za uzastopno stampanje
;; blanko znaka.
(defun print-blank (blanks)
  (cond
    ((zerop blanks) nil)
    (t (format t " - ") (print-blank (- blanks 1)) )
  )
)

(defun states-to-matrix (lvl dim states)
  (cond
    ((> lvl dim ) nil)
    (t (let* ((value (encode-row lvl dim (car states) (cadr states) nil 0))) (append (list (car value)) (states-to-matrix (+ lvl 1) dim (cadr value)))))
    )
)


(defun encode-row (lvl dim fst sec res sum)
  (cond
    ((null (next-value lvl fst sec)) (cond
                                       ((equalp dim sum) (list res (list fst sec)))
                                       (t (list (append res (list(- dim sum))) (list fst sec)))))
    (t (let* ((value (next-value lvl fst sec)))
         (cond
           ((equalp dim (caar value))  (list (append res (cond ((equalp (- (caar value) 1) sum )(list (car value)))
                                                               (t (list (- (caar value) sum 1) (car value))))) (list (cadr value) (caddr value))))
           ((null res)(encode-row lvl dim (cadr value) (caddr value) (cond ((equalp (caar value) 1) (list(car value)))
                                                                           (t (list (- (caar value) 1) (car value)))) (caar value) ))
           ((equalp (- (caar value) 1) sum) (encode-row lvl dim (cadr value) (caddr value) (append res (list(car value))) (caar value)) )
           (t (encode-row lvl dim (cadr value) (caddr value) (append res (list (- (caar value) sum 1) (car value))) (caar value)))
           ))
       )
    )
)

(defun next-value (lvl fst sec)
  (cond
    ((equalp (caar fst) lvl) (cond
                                   ((equalp (caar sec) lvl) (cond
                                                              ((< (cadar fst) (cadar sec)) (list (list (cadar fst) 'x) (cdr fst) sec))
                                                             (t (list (list (cadar sec) 'o) fst (cdr sec)))))
                                   (t (list (list (cadar fst) 'x) (cdr fst) sec))))
    ((equalp (caar sec) lvl) (list (list (cadar sec) 'o) fst (cdr sec)))
    (t nil)
    )
)
