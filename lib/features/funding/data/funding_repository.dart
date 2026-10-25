import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

enum FundingList { explore, mine, wishlist }

const invalidFundingResponse =
    ApiException('Respons pendanaan dari server tidak valid.');

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) throw invalidFundingResponse;
  return value;
}

int _int(Object? value) {
  if (value is! int || value < 0) throw invalidFundingResponse;
  return value;
}

String _text(Object? value) {
  if (value is! String) throw invalidFundingResponse;
  return value;
}

class FundingCategory {
  final int id;
  final String name;
  const FundingCategory(this.id, this.name);
  factory FundingCategory.parse(Object? value) {
    final data = _map(value);
    return FundingCategory(_int(data['id']), _text(data['name']));
  }
}

class FundingRecord {
  final int id;
  final String title;
  final String description;
  final int targetAmount;
  final int ownerId;
  final String ownerName;
  final FundingCategory category;
  final String status;
  final bool saved;
  final String? photoUrl;

  const FundingRecord(
      {required this.id,
      required this.title,
      required this.description,
      required this.targetAmount,
      required this.ownerId,
      required this.ownerName,
      required this.category,
      required this.status,
      required this.saved,
      this.photoUrl});

  factory FundingRecord.parse(Object? value) {
    final data = _map(value);
    final owner = _map(data['owner']);
    if (!['draft', 'published'].contains(data['status']) ||
        data['is_wishlisted'] is! bool ||
        (data['photo_url'] != null && data['photo_url'] is! String)) {
      throw invalidFundingResponse;
    }
    return FundingRecord(
        id: _int(data['id']),
        title: _text(data['title']),
        description: _text(data['description']),
        targetAmount: _int(data['target_amount']),
        ownerId: _int(owner['id']),
        ownerName: _text(owner['name']),
        category: FundingCategory.parse(data['category']),
        status: data['status'] as String,
        saved: data['is_wishlisted'] as bool,
        photoUrl: data['photo_url'] as String?);
  }
}

class FundingPage {
  final List<FundingRecord> items;
  final int page;
  final int lastPage;
  final int total;
  const FundingPage(
      {required this.items,
      required this.page,
      required this.lastPage,
      required this.total});
  factory FundingPage.parse(Object? value) {
    final data = _map(value);
    final meta = _map(data['pagination']);
    final items = data['items'];
    if (items is! List) throw invalidFundingResponse;
    final page = _int(meta['page']);
    final lastPage = _int(meta['last_page']);
    if (page < 1 || lastPage < 1) throw invalidFundingResponse;
    return FundingPage(
        items: items.map(FundingRecord.parse).toList(),
        page: page,
        lastPage: lastPage,
        total: _int(meta['total']));
  }
}

class FundingDraft {
  final String title;
  final String description;
  final int categoryId;
  final int targetAmount;
  final String status;
  final MultipartPhoto? photo;
  final bool removePhoto;
  const FundingDraft(
      {required this.title,
      required this.description,
      required this.categoryId,
      required this.targetAmount,
      required this.status,
      this.photo,
      this.removePhoto = false});
  Map<String, Object?> toJson() => {
        'title': title.trim(),
        'description': description.trim(),
        'category_id': categoryId,
        'target_amount': targetAmount,
        'status': status,
        if (removePhoto) 'remove_photo': true,
      };
}

abstract interface class FundingGateway {
  Future<List<FundingCategory>> categories();
  Future<FundingPage> list(FundingList mode,
      {int page = 1, String search = '', int? categoryId, String? status});
  Future<FundingRecord> detail(int id, {bool mine = false});
  Future<FundingRecord> save(FundingDraft draft, {int? id});
  Future<void> setWishlist(int id, bool save);
  Uri? photoUri(FundingRecord funding);
}

class FundingRepository implements FundingGateway {
  final ApiClient _client;
  FundingRepository(this._client);
  @override
  Future<List<FundingCategory>> categories() async {
    final data = _map(await _client.get('categories'));
    if (data['items'] is! List) throw invalidFundingResponse;
    return (data['items'] as List).map(FundingCategory.parse).toList();
  }

  @override
  Future<FundingPage> list(FundingList mode,
      {int page = 1,
      String search = '',
      int? categoryId,
      String? status}) async {
    final path = {
      FundingList.explore: 'fundings',
      FundingList.mine: 'me/fundings',
      FundingList.wishlist: 'me/wishlist'
    }[mode]!;
    final query = Uri(path: path, queryParameters: {
      'page': '$page',
      'per_page': '10',
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (categoryId != null) 'category_id': '$categoryId',
      if (mode == FundingList.mine && status != null) 'status': status
    }).toString();
    return FundingPage.parse(await _client.get(query));
  }

  @override
  Future<FundingRecord> detail(int id, {bool mine = false}) async =>
      FundingRecord.parse(_map(
          await _client.get('${mine ? 'me/' : ''}fundings/$id'))['funding']);
  @override
  Future<FundingRecord> save(FundingDraft draft, {int? id}) async {
    final path = id == null ? 'fundings' : 'fundings/$id';
    final data = draft.photo == null
        ? await _client.request(id == null ? 'POST' : 'PATCH', path,
            body: draft.toJson())
        : await _client
            .request('POST', path, photo: draft.photo, multipartFields: {
            for (final entry in draft.toJson().entries)
              entry.key: entry.value is bool
                  ? (entry.value == true ? '1' : '0')
                  : entry.value.toString(),
            if (id != null) '_method': 'PATCH'
          });
    return FundingRecord.parse(_map(data)['funding']);
  }

  @override
  Future<void> setWishlist(int id, bool save) async {
    await _client.request(save ? 'PUT' : 'DELETE', 'fundings/$id/wishlist');
  }

  @override
  Uri? photoUri(FundingRecord funding) {
    final path = funding.photoUrl;
    if (path == null || !path.startsWith('/storage/fundings/')) return null;
    final uri = _client.baseUri.resolve(path);
    if (uri.origin != _client.baseUri.origin ||
        !uri.path.startsWith('/storage/fundings/') ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }
}
