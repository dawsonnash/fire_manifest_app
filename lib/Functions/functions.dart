String capitalizeEveryWord(String input) {
  return input
      .split(' ') // Split the string into words
      .map((word) {
    if (word == word.toUpperCase() && word != word.toLowerCase()) {
      // If the word is all uppercase and not just symbols or numbers, keep it as is
      return word;
    }
    return word.isNotEmpty
        ? word[0].toUpperCase() + word.substring(1).toLowerCase()
        : ''; // Capitalize each word
  })
      .join(' '); // Join the words back with spaces
}
