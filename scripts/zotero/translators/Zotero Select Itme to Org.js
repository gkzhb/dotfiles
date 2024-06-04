{
"translatorID":"16B3C1D9-5FD7-44A0-954A-DC4639172D66",
"translatorType":2,
"label":"Zotero Select Item to OrgMode",
"creator":"gkzhb",
"target":"html",
"minVersion":"2.0",
"maxVersion":"",
"priority":200,
"inRepository":false,
"lastUpdated":"2024-04-12 11:10:00"
}

function doExport() {
	var item;
	while(item = Zotero.nextItem()) {
		var library_id = item.libraryID ? item.libraryID : 0;
		// Zotero.write("[[zotero://select/items/" + library_id + "_" + item.key + "][" + item.title + " - Zotero]]");
		Zotero.write(`[[zotero://select/items/${library_id}_${item.key}][${item.title} - Zotero]]`);
    // Zotero.write("")
	}
}
