define i32 @external_helper(ptr %out, i32 %value) {
entry:
  %previous = load i32, ptr %out, align 4
  %next = add nsw i32 %previous, %value
  store i32 %next, ptr %out, align 4
  ret i32 %next
}
