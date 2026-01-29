export const scrollToElementById = (id: string, behavior: any = 'smooth') => {
  if (!id) return;
  const element = document.getElementById(id);
  if (element) {
    element.scrollIntoView({ behavior });
  }
};
