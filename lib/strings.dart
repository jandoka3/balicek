/// Všechny texty UI na jednom místě (čeština). Připraveno na pozdější překlad.
class S {
  // Obecné
  static const appTitle = 'Balíček';
  static const cancel = 'Zrušit';
  static const ok = 'OK';
  static const save = 'Uložit';
  static const delete = 'Smazat';
  static const rename = 'Přejmenovat';
  static const create = 'Vytvořit';
  static const add = 'Přidat';
  static const edit = 'Upravit';
  static const done = 'Hotovo';

  // Přehled seznamů
  static const listsTitle = 'Moje seznamy';
  static const emptyLists =
      'Zatím nemáš žádný seznam – vytvoř první tlačítkem +';
  static const newListTitle = 'Nový seznam';
  static const newEmptyList = 'Nový prázdný seznam';
  static const copyExistingList = 'Kopie existujícího seznamu';
  static const importFromText = 'Import z textu';
  static const listNameHint = 'např. Rodinná dovolená';
  static const chooseSourceList = 'Vyber seznam ke zkopírování';
  static const deleteListConfirm = 'Opravdu smazat tento seznam?';
  static const renameList = 'Přejmenovat seznam';

  static String itemsCount(int n) {
    if (n == 1) return '1 položka';
    if (n >= 2 && n <= 4) return '$n položky';
    return '$n položek';
  }

  // Detail / režim balení
  static const days = 'Počet dní';
  static const reset = 'Reset';
  static const resetConfirmTitle = 'Reset balení';
  static const resetConfirmBody = 'Odškrtnout všechny položky?';
  static const resetChangeDays = 'Chceš změnit i počet dní?';
  static const emptyItems =
      'Seznam je prázdný – přidej položky tlačítkem Upravit';

  static String packed(int done, int total) => 'Sbaleno $done/$total';
  static String pieces(int n) => '$n ks';

  // Editace
  static const editTitle = 'Úprava seznamu';
  static const addItem = 'Přidat položku';
  static const itemName = 'Název položky';
  static const itemNameHint = 'např. Tričko';
  static const quantityMode = 'Množství';
  static const modePerDay = 'X kusů na den';
  static const modePerXDays = '1 kus na X dní';
  static const modeFixed = 'X kusů celkem (bez ohledu na dny)';
  static const value = 'Hodnota';
  static const deleteItemConfirm = 'Smazat tuto položku?';

  // Hromadný výběr položek
  static const selectItems = 'Vybrat položky';
  static const selectionCancel = 'Zrušit výběr';

  static String selectedCount(int n) {
    final word = n == 1
        ? 'položka'
        : (n >= 2 && n <= 4 ? 'položky' : 'položek');
    return '$n $word vybráno';
  }

  static String deleteSelectedConfirm(int n) {
    final word = n == 1
        ? 'položku'
        : (n >= 2 && n <= 4 ? 'položky' : 'položek');
    return 'Smazat $n $word?';
  }

  // Import
  static const importTitle = 'Import položek';
  static const importHint =
      'Vlož položky – každou na nový řádek nebo oddělené čárkami';
  static const importEmpty = 'Nenašla jsem žádné položky k importu';

  // Kategorie
  static const category = 'Kategorie';
  static const addCategory = 'Přidat kategorii';
  static const addSubcategory = 'Přidat podkategorii';
  static const newCategoryTitle = 'Nová kategorie';
  static const categoryName = 'Název kategorie';
  static const categoryNameHint = 'např. Oblečení';
  static const renameCategory = 'Přejmenovat kategorii';
  static const deleteCategory = 'Smazat kategorii';
  static const addItemToCategory = 'Přidat položku do kategorie';
  static const noCategory = 'Bez kategorie';
  static const moveToCategory = 'Přesunout do kategorie';
  static const chooseCategory = 'Zvolit kategorii';
  static const cycleNotAllowed =
      'Kategorii nelze vložit do sebe sama ani do své podkategorie';

  /// Dialog při mazání kategorie – co s položkami uvnitř.
  static const deleteCategoryTitle = 'Smazat kategorii';
  static const deleteCategoryBody =
      'Co se má stát s položkami a podkategoriemi v této kategorii?';
  static const deleteCategoryAndItems = 'Smazat i položky';
  static const deleteCategoryMoveUp = 'Přesunout o úroveň výš';
}
