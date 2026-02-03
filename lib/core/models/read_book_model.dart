class ReadBook {
  String? kind;
  int? totalItems;
  List<Items>? items;

  ReadBook({this.kind, this.totalItems, this.items});

  ReadBook.fromJson(Map<String, dynamic> json) {
    kind = json['kind'];
    totalItems = json['totalItems'];
    if (json['items'] != null) {
      items = <Items>[];
      json['items'].forEach((v) {
        items!.add(Items.fromJson(v));
      });
    }
  }
}

class Items {
  String? kind;
  String? id;
  String? etag;
  String? selfLink;
  VolumeInfo? volumeInfo;
  SaleInfo? saleInfo;
  AccessInfo? accessInfo;
  SearchInfo? searchInfo;

  Items({
    this.kind,
    this.id,
    this.etag,
    this.selfLink,
    this.volumeInfo,
    this.saleInfo,
    this.accessInfo,
    this.searchInfo,
  });

  Items.fromJson(Map<String, dynamic> json) {
    kind = json['kind'];
    id = json['id'];
    etag = json['etag'];
    selfLink = json['selfLink'];
    volumeInfo = json['volumeInfo'] != null
        ? VolumeInfo.fromJson(json['volumeInfo'])
        : null;
    saleInfo = json['saleInfo'] != null
        ? SaleInfo.fromJson(json['saleInfo'])
        : null;
    accessInfo = json['accessInfo'] != null
        ? AccessInfo.fromJson(json['accessInfo'])
        : null;
    searchInfo = json['searchInfo'] != null
        ? SearchInfo.fromJson(json['searchInfo'])
        : null;
  }
}

class VolumeInfo {
  String? title;
  List<String>? authors;
  String? publishedDate;
  String? description;
  ImageLinks? imageLinks;
  String? previewLink;
  String? infoLink;

  VolumeInfo({
    this.title,
    this.authors,
    this.publishedDate,
    this.description,
    this.imageLinks,
    this.previewLink,
    this.infoLink,
  });

  VolumeInfo.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    if (json['authors'] != null) {
      authors = json['authors'].cast<String>();
    }
    publishedDate = json['publishedDate'];
    description = json['description'];
    imageLinks = json['imageLinks'] != null
        ? ImageLinks.fromJson(json['imageLinks'])
        : null;
    previewLink = json['previewLink'];
    infoLink = json['infoLink'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['authors'] = authors;
    data['publishedDate'] = publishedDate;
    data['description'] = description;
    if (imageLinks != null) {
      data['imageLinks'] = imageLinks!.toJson();
    }
    data['previewLink'] = previewLink;
    data['infoLink'] = infoLink;
    return data;
  }
}

class ImageLinks {
  String? smallThumbnail;
  String? thumbnail;

  ImageLinks({this.smallThumbnail, this.thumbnail});

  ImageLinks.fromJson(Map<String, dynamic> json) {
    smallThumbnail = json['smallThumbnail'];
    thumbnail = json['thumbnail'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['smallThumbnail'] = smallThumbnail;
    data['thumbnail'] = thumbnail;
    return data;
  }
}

// ... (Baki classes same rahengi jese aapne di thi, SaleInfo, AccessInfo etc.
// Main unhen skip kar raha hon space bachane k liye, lekin wo zaroori hen
// agar aap poora json parse kar rahe hen. Uper wali classes most important hen) ...
class SaleInfo {
  SaleInfo.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson() => {};
}

class AccessInfo {
  AccessInfo.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson() => {};
}

class SearchInfo {
  SearchInfo.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson() => {};
}
