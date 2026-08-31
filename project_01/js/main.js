document.addEventListener('DOMContentLoaded', function () {
    // slideDown
    function slideDown(element, duration = 300) {
        if (!element) return;

        element.getAnimations().forEach(function (animation) {
            animation.cancel();
        });

        element.style.display = 'block';

        const height = element.scrollHeight;

        const animation = element.animate(
            [
                {
                    height: '0',
                    opacity: 0,
                    overflow: 'hidden'
                },
                {
                    height: height + 'px',
                    opacity: 1,
                    overflow: 'hidden'
                }
            ],
            {
                duration: duration,
                easing: 'ease'
            }
        );

        animation.onfinish = function () {
            element.style.height = '';
            element.style.opacity = '';
            element.style.overflow = '';
        };
    }

    // slideUp
    function slideUp(element, duration = 300) {
        if (!element) return;

        element.getAnimations().forEach(function (animation) {
            animation.cancel();
        });

        const height = element.offsetHeight;

        const animation = element.animate(
            [
                {
                    height: height + 'px',
                    opacity: 1,
                    overflow: 'hidden'
                },
                {
                    height: '0',
                    opacity: 0,
                    overflow: 'hidden'
                }
            ],
            {
                duration: duration,
                easing: 'ease'
            }
        );

        animation.onfinish = function () {
            element.style.display = 'none';
            element.style.height = '';
            element.style.opacity = '';
            element.style.overflow = '';
        };
    }

    // fadeOut
    function fadeOut(element, duration = 300) {
        if (!element) return;

        element.getAnimations().forEach(function (animation) {
            animation.cancel();
        });

        const animation = element.animate(
            [
                { opacity: 1 },
                { opacity: 0 }
            ],
            {
                duration: duration,
                easing: 'ease'
            }
        );

        animation.onfinish = function () {
            element.style.display = 'none';
            element.style.opacity = '';
        };
    }

    // 1. 장바구니
    const cartBox = document.querySelector('.cart_box');
    const cartTargets = document.querySelectorAll('.btn_cart, .cart_box');

    cartTargets.forEach(function (target) {
        target.addEventListener('mouseenter', function () {
            slideDown(cartBox, 300);
        });

        target.addEventListener('mouseleave', function () {
            slideUp(cartBox, 300);
        });
    });

    // 2. 최근 본 상품
    const recentBox = document.querySelector('.recent_box');
    const recentTargets = document.querySelectorAll(
        '.btn_recent, .recent_box'
    );

    recentTargets.forEach(function (target) {
        target.addEventListener('mouseenter', function () {
            slideDown(recentBox, 300);
        });

        target.addEventListener('mouseleave', function () {
            slideUp(recentBox, 300);
        });
    });

    // ※ 결제하기 버튼
    const checkoutButton = document.querySelector('.checkout-button');

    if (checkoutButton) {
        checkoutButton.addEventListener('click', function () {
            alert('결제 기능은 현재 준비 중입니다.');
        });
    }

    // 3. TOP 버튼 부드럽게 스크롤
    const topButton = document.querySelector('.btn_top');

    if (topButton) {
        topButton.addEventListener('click', function (event) {
            event.preventDefault();

            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    }

    // 사용법 닫기
    const howUseClose = document.querySelector('.how_use_close');
    const howUseWrap = document.querySelector('.how_use_wrap');

    if (howUseClose) {
        howUseClose.addEventListener('click', function () {
            fadeOut(howUseWrap, 300);
        });
    }

    // 검색창 열고 닫기
    const searchToggle = document.querySelector('.search_toggle');
    const searchBox = document.querySelector('.search_box');
    const searchText = document.querySelector('.search_txt');

    if (searchToggle && searchBox) {
        searchToggle.addEventListener('click', function () {
            searchBox.classList.toggle('on');

            if (searchBox.classList.contains('on')) {
                searchToggle.innerHTML =
                    '<i class="fa-solid fa-xmark"></i>';

                searchToggle.setAttribute(
                    'aria-label',
                    '검색창 닫기'
                );

                if (searchText) {
                    searchText.focus();
                }
            } else {
                searchToggle.innerHTML =
                    '<i class="fa-solid fa-magnifying-glass"></i>';

                searchToggle.setAttribute(
                    'aria-label',
                    '검색창 열기'
                );
            }
        });
    }

    // FAQ 하나만 열기
    const faqDetails = document.querySelectorAll(
        '.faq_box details'
    );

    faqDetails.forEach(function (detail) {
        detail.addEventListener('toggle', function () {
            if (!detail.open) return;

            faqDetails.forEach(function (otherDetail) {
                if (otherDetail !== detail) {
                    otherDetail.removeAttribute('open');
                }
            });
        });
    });

    // 상세페이지가 없는 상품 알림
    const productAlertLinks = document.querySelectorAll(
        '.product_alert a'
    );

    productAlertLinks.forEach(function (link) {
        link.addEventListener('click', function (event) {
            event.preventDefault();

            alert(
                '현재는 만년 업무 플래너만 상세페이지가 제작되어 있습니다.'
            );
        });
    });
});