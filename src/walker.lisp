(in-package #:uglify-js)

(defmacro ast-case (expr &body body)
  (let ((ex (gensym "AST")))
    `(let ((,ex ,expr))
       (case (car ,ex)
         ,@(loop :for i :in body
              :for c = (car i)
              :for a = (cadr i)
              :for b = (cddr i)
              :if a :collect `(,c (destructuring-bind ,a (cdr ,ex) ,@b))
              :else :collect `(,c ,@b))))))

(defmacro ast-walk ((ast &optional (expr 'expr) (walk 'walk)) &body body)
  `(labels ((,walk (,expr)
              (when ,expr
                (or (progn ,@body)
                    (ast-case ,expr
                      ((:function :defun) (name args body) `(,(car ,expr) ,name ,args ,(mapcar #',walk body)))
                      ((:var :const) (defs) (list (car ,expr)
                                                  (mapcar (lambda (def)
                                                            `(,(car def) ,@(,walk (cdr def)))) defs)))
                      (:array (a) `(:array ,(mapcar #',walk a)))
                      (:assign (op left right) `(:assign ,op ,(,walk left) ,(,walk right)))
                      (:atom (a) `(:atom ,a))
                      (:binary (op left right) `(:binary ,op ,(,walk left) ,(,walk right)))
                      (:block (body) `(:block ,(mapcar #',walk body)))
                      (:break (label) `(:break ,label))
                      (:call (expr args) `(:call ,(,walk expr) ,(mapcar #',walk args)))
                      (:conditional (cond then else) `(:conditional ,(,walk cond) ,(,walk then) ,(,walk else)))
                      (:continue (label) `(:continue ,label))
                      (:do (cond body) `(:do ,(,walk cond) ,(,walk body)))
                      (:dot (expr prop) `(:dot ,(,walk expr) ,prop))
                      (:for (init cond step body) `(:for ,(,walk init) ,(,walk cond) ,(,walk step) ,(,walk body)))
                      (:for-in (has-var key hash body) `(:for-in ,has-var ,key ,(,walk hash) ,(,walk body)))
                      (:if (cond then else) `(:if ,(,walk cond) ,(,walk then) ,(,walk else)))
                      (:label (label body) `(:label ,label ,(,walk body)))
                      (:name (name) `(:name ,name))
                      (:new (ctor args) `(:new ,(,walk ctor) ,(mapcar #',walk args)))
                      (:num (n) `(:num ,n))
                      (:object (props) `(:object ,(mapcar (lambda (def)
                                                            `(,(car def) ,@(,walk (cdr def)))) props)))
                      (:regexp (pattern modifiers) `(:regexp ,pattern ,modifiers))
                      (:return (expr) `(:return ,(,walk expr)))
                      (:seq (one two) `(:seq ,(,walk one) ,(,walk two)))
                      (:stat (stmt) `(:stat ,(,walk stmt)))
                      (:string (str) `(:string ,str))
                      (:sub (expr sub) `(:sub ,(,walk expr) ,(,walk sub)))
                      (:switch (expr body) `(:switch ,(,walk expr)
                                                     ,(mapcar (lambda (branch)
                                                                `(,(walk (car branch))
                                                                   ,@(mapcar #',walk (cdr branch)))) body)))
                      (:throw (expr) `(:throw ,(,walk expr)))
                      (:toplevel (body) `(:toplevel ,(mapcar #',walk body)))
                      (:try (tr ca fi) `(:try ,(,walk tr)
                                              ,(when ca `(,(car ca) ,@(,walk (cdr ca))))
                                              ,(when fi (,walk fi))))
                      (:unary-postfix (op expr) `(:unary-postfix ,op ,(,walk expr)))
                      (:unary-prefix (op expr) `(:unary-prefix ,op ,(,walk expr)))
                      (:while (cond body) `(:while ,(,walk cond) ,(,walk body)))
                      (:with (expr body) `(:while ,(,walk expr) ,(,walk body))))))))
     (,walk ,ast)))
