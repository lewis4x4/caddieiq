import { Text, TouchableOpacity, TouchableOpacityProps, View } from 'react-native';
import { cn } from '../../lib/utils';
import { forwardRef } from 'react';

interface ButtonProps extends TouchableOpacityProps {
    variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link';
    size?: 'default' | 'sm' | 'lg' | 'icon';
    className?: string;
    textClassName?: string;
}

const Button = forwardRef<View, ButtonProps>(
    ({ className, variant = 'default', size = 'default', textClassName, children, ...props }, ref) => {
        return (
            <TouchableOpacity
                ref={ref}
                className={cn(
                    'inline-flex items-center justify-center rounded-xl font-medium ring-offset-background disabled:opacity-50 disabled:pointer-events-none',
                    {
                        'bg-golf text-white active:opacity-90': variant === 'default',
                        'bg-red-500 text-white active:opacity-90': variant === 'destructive',
                        'border border-zinc-700 bg-background active:bg-zinc-800': variant === 'outline',
                        'bg-zinc-800 text-zinc-100 active:bg-zinc-700': variant === 'secondary',
                        'active:bg-zinc-800': variant === 'ghost',
                        'text-golf underline-offset-4 active:underline': variant === 'link',
                        'h-12 px-6 py-3': size === 'default',
                        'h-10 rounded-lg px-4': size === 'sm',
                        'h-14 rounded-2xl px-10': size === 'lg',
                        'h-12 w-12': size === 'icon',
                    },
                    className
                )}
                {...props}
            >
                <Text
                    className={cn(
                        'text-base font-semibold',
                        {
                            'text-white': variant === 'default' || variant === 'destructive',
                            'text-zinc-100': variant === 'secondary' || variant === 'outline' || variant === 'ghost',
                            'text-golf': variant === 'link',
                        },
                        textClassName
                    )}
                >
                    {children}
                </Text>
            </TouchableOpacity>
        );
    }
);
Button.displayName = 'Button';

export { Button };
