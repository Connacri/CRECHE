import sys

file_path = 'lib/models/course_model_complete.dart'
with open(file_path, 'r') as f:
    content = f.read()

extra_methods = """
  bool hasAvailableSpots() {
    return currentStudents < maxStudents;
  }

  int get availableSpots => maxStudents - currentStudents;
"""

if 'bool hasAvailableSpots()' not in content:
    # Insert before the last closing brace of CourseModel class
    last_brace_index = content.rfind('}')
    content = content[:last_brace_index] + extra_methods + content[last_brace_index:]

with open(file_path, 'w') as f:
    f.write(content)
