import '../../exports.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showSearch;
  final bool showLogo;
  final VoidCallback? onSearchTap;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    this.title,
    this.showSearch = false,
    this.showLogo = false,
    this.onSearchTap,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 10.h,
        bottom: 10.h,
        left: AppDimens.kPadding,
        right: AppDimens.kPadding,
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Leading: Back Button or Logo
          if (showBackButton && Navigator.canPop(context))
            GestureDetector(
              onTap: () => navigation.pop(context),
              child: const Icon(Icons.arrow_back, color: blackColor),
            )
          else if (showLogo)
            Image.asset(AppAssets.logoIcon, height: 35.h)
          else
            const SizedBox.shrink(),

          if (showBackButton || showLogo) gapW12,

          // 2. Middle: Search Bar or Title
          Expanded(
            child: showSearch
                ? GestureDetector(
                    onTap: onSearchTap,
                    child: Container(
                      height: 40.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          gapW8,
                          Text("Search books...", style: AppStyles.bodySmall),
                        ],
                      ),
                    ),
                  )
                : Text(
                    title ?? "",
                    style: AppStyles.headingMedium.copyWith(fontSize: 18.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),

          // 3. Trailing: Actions (Notification icon etc.)
          if (actions != null) ...[gapW12, ...actions!],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.h);
}
