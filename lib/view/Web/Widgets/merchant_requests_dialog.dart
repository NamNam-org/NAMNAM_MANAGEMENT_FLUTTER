import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namnam/core/Utility/appcolors.dart';
import 'package:namnam/model/merchant_request.dart';
import 'package:namnam/model/request/update_merchant_status_request.dart';
import 'package:namnam/view/Web/Widgets/custom_toast.dart';
import 'package:namnam/view/Web/Widgets/merchant_request_decision_dialog.dart';
import 'package:namnam/viewmodel/merchants_view_model.dart';
import 'package:provider/provider.dart';

/// Two-step dialog over `GET merchants/merchant-requests`: a row per request,
/// tapping one opens its full detail with approve/reject. The fetch is fired
/// as the dialog opens.
class MerchantRequestsDialog extends StatefulWidget {
  const MerchantRequestsDialog({super.key});

  static Future<void> show(BuildContext context) {
    context.read<MerchantsViewModel>().fetchMerchantRequests();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const MerchantRequestsDialog(),
    );
  }

  @override
  State<MerchantRequestsDialog> createState() => _MerchantRequestsDialogState();
}

class _MerchantRequestsDialogState extends State<MerchantRequestsDialog> {
  /// Tracked by id rather than by object: every refresh rebuilds the list with
  /// new instances, and a request that disappears (because it was just decided)
  /// resolves back to null, returning the panel to the rows on its own.
  int? _openRequestId;

  MerchantRequest? _resolveOpenRequest(MerchantsViewModel vm) {
    if (_openRequestId == null) return null;
    for (final request in vm.merchantRequests) {
      if (request.requestId == _openRequestId) return request;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantsViewModel>(
      builder: (context, vm, _) {
        final open = _resolveOpenRequest(vm);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: _buildTitle(vm, open),
          content: SizedBox(
            width: 620,
            height: 460,
            child: open != null
                ? _buildDetails(context, vm, open)
                : _buildRequestRows(vm),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitle(MerchantsViewModel vm, MerchantRequest? open) {
    final count = vm.merchantRequests.length;
    final showsCount = !vm.isLoadingRequests && count > 0;

    return Row(
      children: [
        if (open == null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Appcolors.appPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: Appcolors.appPrimaryColor,
              size: 24,
            ),
          )
        else
          IconButton(
            onPressed: () => setState(() => _openRequestId = null),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to requests',
            color: Appcolors.textPrimaryColor,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                open == null
                    ? 'Merchant Requests'
                    : (open.merchant?.name ?? 'Unnamed Merchant'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                open != null
                    ? (open.requestId != null
                        ? 'Request #${open.requestId}'
                        : 'Request details')
                    : showsCount
                        ? '$count ${count == 1 ? 'request' : 'requests'}'
                        : 'Merchant onboarding requests',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed:
              vm.isLoadingRequests ? null : () => vm.fetchMerchantRequests(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          color: Appcolors.appPrimaryColor,
        ),
      ],
    );
  }

  /// Shared loading/error/empty handling for both steps; returns null when
  /// there is real content to show.
  Widget? _buildPlaceholder(MerchantsViewModel vm) {
    if (vm.isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = vm.requestsErrorMessage;
    if (error != null && error.isNotEmpty) {
      return _EmptyState(
        icon: Icons.error_outline,
        iconColor: Appcolors.appPrimaryColor,
        title: 'Couldn\'t load requests',
        message: error,
        action: TextButton.icon(
          onPressed: () => vm.fetchMerchantRequests(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Try again'),
          style: TextButton.styleFrom(
            foregroundColor: Appcolors.appPrimaryColor,
          ),
        ),
      );
    }

    if (vm.merchantRequests.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No requests to review',
        message: 'Nothing is waiting on a decision right now.',
      );
    }

    return null;
  }

  Widget _buildRequestRows(MerchantsViewModel vm) {
    final placeholder = _buildPlaceholder(vm);
    if (placeholder != null) return placeholder;

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: vm.merchantRequests.length,
      separatorBuilder: (_, index) =>
          Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (_, index) {
        final request = vm.merchantRequests[index];
        return _RequestRow(
          request: request,
          onTap: request.requestId == null
              ? null
              : () => setState(() => _openRequestId = request.requestId),
        );
      },
    );
  }

  /// Only reached when the request resolved out of a loaded list, so no
  /// loading/error handling is needed here.
  Widget _buildDetails(
    BuildContext context,
    MerchantsViewModel vm,
    MerchantRequest request,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: _RequestCard(
        request: request,
        isUpdating: vm.isUpdatingStatus,
        // Deliberately bound to the dialog's context rather than the card's:
        // the post-update refresh rebuilds the card, which would leave its own
        // context defunct mid-flow.
        onDecision: (status) => _handleDecision(context, vm, request, status),
      ),
    );
  }

  /// Confirms the decision, sends it, and reports the outcome.
  Future<void> _handleDecision(
    BuildContext context,
    MerchantsViewModel vm,
    MerchantRequest request,
    String status,
  ) async {
    final merchantId = request.merchantId;
    if (merchantId == null) {
      ToastManager.show(
        context: context,
        message: 'This request has no merchant id, so it can\'t be updated.',
        type: ToastType.error,
      );
      return;
    }

    final zoneId = await MerchantRequestDecisionDialog.show(
      context: context,
      request: request,
      status: status,
    );

    // Null means the decision dialog was cancelled.
    if (zoneId == null || !context.mounted) return;

    final success = await vm.updateMerchantStatus(
      merchantId: merchantId,
      status: status,
      zoneId: zoneId,
    );
    if (!context.mounted) return;

    final isApprove = status == UpdateMerchantStatusRequest.approved;
    ToastManager.show(
      context: context,
      message: success
          ? 'Request ${isApprove ? 'approved' : 'rejected'} successfully!'
          : (vm.updateErrorMessage?.isNotEmpty == true
              ? vm.updateErrorMessage!
              : 'Failed to update the merchant request'),
      type: success ? ToastType.success : ToastType.error,
    );
  }
}

/// One row in the list step: enough to recognise the request, not the detail.
class _RequestRow extends StatelessWidget {
  final MerchantRequest request;
  final VoidCallback? onTap;

  const _RequestRow({required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    final merchant = request.merchant;
    final subtitleParts = [
      if (request.requestId != null) 'Request #${request.requestId}',
      if (request.createdAt != null) formatDateTime(request.createdAt!),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: _RemoteImage(
        candidates: [if (merchant?.logoUrl != null) merchant!.logoUrl!],
        width: 40,
        height: 40,
        borderRadius: 8,
        fallbackIcon: Icons.store,
      ),
      title: Text(
        merchant?.name ?? 'Unnamed Merchant',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Appcolors.textPrimaryColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitleParts.join(' · '),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (request.status != null) _StatusBadge(status: request.status!),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _RequestCard extends StatelessWidget {
  final MerchantRequest request;
  final bool isUpdating;
  final void Function(String status) onDecision;

  const _RequestCard({
    required this.request,
    required this.isUpdating,
    required this.onDecision,
  });

  /// Only a pending request can still be decided on.
  bool get _isPending => request.status?.trim().toLowerCase() == 'pending';

  @override
  Widget build(BuildContext context) {
    final merchant = request.merchant;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (merchant?.coverUrl != null)
            _RemoteImage(
              candidates: [merchant!.coverUrl!],
              height: 96,
              width: double.infinity,
              borderRadius: 0,
              fallbackIcon: Icons.image_outlined,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequestHeader(),
                if (merchant != null) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 14),
                  _buildMerchantIdentity(merchant),
                  if (merchant.category != null) ...[
                    const SizedBox(height: 12),
                    _CategoryChip(category: merchant.category!),
                  ],
                  const SizedBox(height: 16),
                  ..._buildMerchantDetails(merchant),
                ],
                for (final entry in request.extras.entries)
                  _DetailRow(
                    label: prettifyKey(entry.key),
                    value: stringifyValue(entry.value),
                  ),
                if (_isPending) ...[
                  const SizedBox(height: 4),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 12),
                  _buildDecisionActions(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isUpdating
                ? null
                : () => onDecision(UpdateMerchantStatusRequest.rejected),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isUpdating
                ? null
                : () => onDecision(UpdateMerchantStatusRequest.approved),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.requestId != null
                    ? 'Request #${request.requestId}'
                    : 'Request',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Appcolors.textPrimaryColor,
                ),
              ),
              if (request.createdAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Submitted ${formatDateTime(request.createdAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
        if (request.status != null) _StatusBadge(status: request.status!),
      ],
    );
  }

  Widget _buildMerchantIdentity(RequestedMerchant merchant) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RemoteImage(
          candidates: [if (merchant.logoUrl != null) merchant.logoUrl!],
          width: 48,
          height: 48,
          borderRadius: 10,
          fallbackIcon: Icons.store,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                merchant.name ?? 'Unnamed Merchant',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Appcolors.textPrimaryColor,
                ),
              ),
              if (merchant.description != null) ...[
                const SizedBox(height: 3),
                Text(
                  merchant.description!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMerchantDetails(RequestedMerchant merchant) {
    final location = merchant.location;

    return [
      if (merchant.merchantId != null)
        _DetailRow(label: 'Merchant ID', value: '${merchant.merchantId}'),
      if (merchant.hotlineNumber != null)
        _DetailRow(label: 'Hotline', value: merchant.hotlineNumber!),
      if (location?.formattedAddress != null)
        _DetailRow(label: 'Address', value: location!.formattedAddress!),
      if (location?.formattedCoordinates != null)
        _DetailRow(label: 'Coordinates', value: location!.formattedCoordinates!),
      _DetailRow(
        label: 'Zone',
        value: merchant.zoneId != null ? '${merchant.zoneId}' : 'Unassigned',
      ),
      if (merchant.isOwnedByApp != null)
        _DetailRow(
          label: 'Owned by app',
          value: merchant.isOwnedByApp! ? 'Yes' : 'No',
        ),
      if (merchant.createdAt != null)
        _DetailRow(
          label: 'Merchant since',
          value: formatDateTime(merchant.createdAt!),
        ),
      if (merchant.notes != null)
        _DetailRow(label: 'Notes', value: merchant.notes!),
      // Anything the API added that isn't mapped above.
      for (final entry in merchant.extras.entries)
        _DetailRow(
          label: prettifyKey(entry.key),
          value: stringifyValue(entry.value),
        ),
    ];
  }
}

class _CategoryChip extends StatelessWidget {
  final RequestedMerchantCategory category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final label = category.categoryName ??
        (category.categoryId != null
            ? 'Category #${category.categoryId}'
            : 'Uncategorised');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RemoteImage(
            candidates: category.iconCandidates,
            width: 22,
            height: 22,
            borderRadius: 11,
            fallbackIcon: Icons.category_outlined,
            iconSize: 14,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Appcolors.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tries each URL in [candidates] in order, advancing on load failure, and
/// falls back to [fallbackIcon] once every candidate has failed. The requests
/// endpoint returns two URLs for a category icon that don't always agree, so
/// a single-URL image would show a broken placeholder whenever the first
/// one is the bad one.
class _RemoteImage extends StatefulWidget {
  final List<String> candidates;
  final double width;
  final double height;
  final double borderRadius;
  final IconData fallbackIcon;
  final double iconSize;

  const _RemoteImage({
    required this.candidates,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.fallbackIcon,
    this.iconSize = 20,
  });

  @override
  State<_RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<_RemoteImage> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _RemoteImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.candidates, widget.candidates)) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.candidates.length) return _buildPlaceholder();

    final url = widget.candidates[_index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.network(
        url,
        key: ValueKey(url),
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          final failedIndex = _index;
          // Move to the next candidate once this frame is done; setState during
          // build is not allowed.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _index == failedIndex) {
              setState(() => _index = failedIndex + 1);
            }
          });
          return _buildPlaceholder();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Icon(
        widget.fallbackIcon,
        color: Colors.grey.shade500,
        size: widget.iconSize,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '')) {
      case 'pending':
      case 'inreview':
      case 'submitted':
        return Colors.orange.shade800;
      case 'approved':
      case 'accepted':
      case 'active':
        return Colors.green.shade700;
      case 'rejected':
      case 'declined':
      case 'cancelled':
      case 'canceled':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey.shade600;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Appcolors.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 48, color: iconColor ?? Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

/// The API sends UTC timestamps; show them in the viewer's own zone.
String formatDateTime(DateTime date) =>
    DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal());

/// `hotlineNumber` / `hotline_number` -> `Hotline number`.
String prettifyKey(String key) {
  final spaced = key
      .replaceAll(RegExp(r'[_\-]'), ' ')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .trim();

  if (spaced.isEmpty) return key;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String stringifyValue(dynamic value) {
  if (value is String) return value;
  if (value is Map || value is List) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
  return value.toString();
}
